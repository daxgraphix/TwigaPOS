import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/domain/entities/sales_transaction.dart';
import '../../../billing/domain/repositories/sales_repository.dart';
import '../../../billing/domain/repositories/customer_repository.dart';
import '../../../product/domain/repositories/stock_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _shopName = 'My Shop';
  late DateTime _today;
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  bool _hasError = false;
  DateTime? _lastLoadTime;

  static const _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _loadDashboardData();

    // Read shop name from ShopBloc state
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.name.isNotEmpty) {
      _shopName = shopState.shop.name;
    }

    // Listen for profile customization changes (name/email) so "Welcome back" updates live
    Hive.box('settings').listenable().addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _getUserDisplayName() {
    final settingsBox = Hive.box('settings');
    final userName = (settingsBox.get('userName', defaultValue: '') as String).trim();
    final userEmail = (settingsBox.get('userEmail', defaultValue: '') as String).trim();
    if (userName.isNotEmpty) {
      return userName.split(' ').first;
    } else if (userEmail.isNotEmpty) {
      return userEmail.split('@').first;
    }
    return 'User';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logout),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
               context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Check if we have cached data and it's still valid
    if (!forceRefresh &&
        _dashboardData.isNotEmpty &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load today's sales data concurrently for better performance
      final salesRepo = context.read<SalesRepository>();
      final customerRepo = context.read<CustomerRepository>();
      final stockRepo = context.read<StockRepository>();

      final startOfDay = DateTime(_today.year, _today.month, _today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Run all data loading operations concurrently
      final results = await Future.wait([
        salesRepo.getSalesByDateRange(startOfDay, endOfDay),
        stockRepo.getLowStockAlerts(),
        customerRepo.getDebtAgingSummary(),
      ]);

      final todaySalesResult = results[0] as Either<Failure, List<SalesTransaction>>;
      final lowStockResult = results[1] as Either<Failure, List<String>>;
      final debtAgingResult = results[2] as Either<Failure, Map<String, double>>;

      final todaySales = todaySalesResult.getOrElse((_) => []);
      final lowStockAlerts = lowStockResult.getOrElse((_) => []);
      final debtAging = debtAgingResult.getOrElse((_) => {});

      // Calculate today's metrics
      double todayRevenue = todaySales.fold<double>(0.0, (double sum, SalesTransaction sale) => sum + sale.totalRevenue);
      double todayProfit = todaySales.fold<double>(0.0, (double sum, SalesTransaction sale) => sum + sale.totalProfit);
      int todayTransactions = todaySales.length;

      if (!mounted) return;

      setState(() {
        _dashboardData = {
          'todayRevenue': todayRevenue,
          'todayProfit': todayProfit,
          'todayTransactions': todayTransactions,
          'lowStockAlerts': lowStockAlerts,
          'totalOutstandingDebt': debtAging['total'] ?? 0.0,
          'overdueDebt': (debtAging['thirtyDays'] ?? 0.0) +
                      (debtAging['sixtyDays'] ?? 0.0) +
                      (debtAging['ninetyDaysPlus'] ?? 0.0),
        };
        _isLoading = false;
        _lastLoadTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS');
    final symbol = AppTheme.getCurrencySymbol(currency);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadDashboardData(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboardData;
    final todayRevenue = data['todayRevenue'] ?? 0.0;
    final todayProfit = data['todayProfit'] ?? 0.0;
    final todayTransactions = data['todayTransactions'] ?? 0;
    final lowStockAlerts = data['lowStockAlerts'] ?? <String>[];
    final totalOutstandingDebt = data['totalOutstandingDebt'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDashboardData(forceRefresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDashboardData(forceRefresh: true),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.getPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            _getUserDisplayName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KPI Cards
              GridView.count(
                crossAxisCount: Responsive.getGridCrossAxisCount(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildKPICard('Today\'s Revenue', '$symbol${todayRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
                  _buildKPICard('Today\'s Profit', '$symbol${todayProfit.toStringAsFixed(0)}', Icons.trending_up, Colors.blue),
                  _buildKPICard('Transactions', '$todayTransactions', Icons.receipt, Colors.orange),
                  _buildKPICard('Outstanding Debt', '$symbol${totalOutstandingDebt.toStringAsFixed(0)}', Icons.account_balance, Colors.red),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: Responsive.getGridCrossAxisCount(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildQuickActionCard('New Sale', 'Process transactions', Icons.add_shopping_cart, Colors.red, () => context.push('/new-sale')),
                  _buildQuickActionCard('View Reports', 'Sales analytics', Icons.bar_chart, Colors.green, () => context.go('/reports')),
                  _buildQuickActionCard('Manage Products', 'Inventory control', Icons.inventory, Colors.orange, () => context.push('/products')),
                  _buildQuickActionCard('Customers', 'Client management', Icons.people, Colors.purple, () => context.push('/customers')),
                ],
              ),

              const SizedBox(height: 24),

              if (lowStockAlerts.isNotEmpty)
                _buildWarningCard('Low Stock Alerts', lowStockAlerts.take(3).join(', ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: Responsive.getCardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard(String title, String message) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}