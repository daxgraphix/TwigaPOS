import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/domain/repositories/sales_repository.dart';
import '../../../billing/domain/entities/sales_transaction.dart';
import '../../../finance/domain/repositories/transaction_repository.dart';
import '../../../finance/domain/entities/transaction.dart';
import '../../../billing/domain/repositories/customer_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic> _reportData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final salesRepo = context.read<SalesRepository>();
      final financeRepo = context.read<TransactionRepository>();
      final customerRepo = context.read<CustomerRepository>();

      // Sales data
      final salesResult = await salesRepo.getSalesByDateRange(_startDate, _endDate);
      final dailyRevenueResult = await salesRepo.getDailyRevenue(_startDate, _endDate);
      final dailyProfitResult = await salesRepo.getDailyProfit(_startDate, _endDate);

      // Product analytics
      final topProductsResult = await salesRepo.getTopPerformingProducts(_startDate, _endDate);
      final lowTurnoverResult = await salesRepo.getLowTurnoverProducts();

      // Financial data
      final transactions = await financeRepo.getTransactionsByDateRange(_startDate, _endDate);

      // Customer data
      final customersResult = await customerRepo.getCustomers();

      salesResult.fold(
        (failure) => _showError('Failed to load sales data'),
        (sales) {
          dailyRevenueResult.fold(
            (failure) => _showError('Failed to load revenue data'),
            (dailyRevenue) {
              dailyProfitResult.fold(
                (failure) => _showError('Failed to load profit data'),
                (dailyProfit) {
                  topProductsResult.fold(
                    (failure) => _showError('Failed to load product analytics'),
                    (topProducts) {
                      lowTurnoverResult.fold(
                        (failure) => _showError('Failed to load low turnover data'),
                        (lowTurnover) {
                          transactions.fold(
                            (failure) => _showError('Failed to load financial data'),
                            (financeTransactions) {
                              customersResult.fold(
                                (failure) => _showError('Failed to load customer data'),
                                (customers) {
                                  setState(() {
                                    _reportData = {
                                      'sales': sales,
                                      'dailyRevenue': dailyRevenue,
                                      'dailyProfit': dailyProfit,
                                      'topProducts': topProducts,
                                      'lowTurnover': lowTurnover,
                                      'financeTransactions': financeTransactions,
                                      'customers': customers,
                                    };
                                    _isLoading = false;
                                  });
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      _showError('Error loading report data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _exportReportToPDF() async {
    try {
      final pdf = pdf_widgets.Document();
      pdf.addPage(
        pdf_widgets.Page(
          build: (pdf_widgets.Context context) {
            return pdf_widgets.Column(
              crossAxisAlignment: pdf_widgets.CrossAxisAlignment.start,
              children: [
                pdf_widgets.Text('TwigaPOS Report',
                    style: pdf_widgets.TextStyle(fontSize: 24, fontWeight: pdf_widgets.FontWeight.bold)),
                pdf_widgets.SizedBox(height: 8),
                pdf_widgets.Text('Period: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                pdf_widgets.SizedBox(height: 20),
                pdf_widgets.Text('Report generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'TwigaPOS Report');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported and shared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportReportToCSV() async {
    try {
      final sales = _reportData['sales'] as List<SalesTransaction>? ?? [];
      final csvData = [
        ['ID', 'Product', 'Quantity', 'Revenue', 'Profit', 'Date'],
        ...sales.map((s) => [
              s.id,
              s.productName,
              s.quantity,
              s.totalRevenue.toStringAsFixed(2),
              s.totalProfit.toStringAsFixed(2),
              s.timestamp.toIso8601String(),
            ]),
      ];

      final csv = const ListToCsvConverter().convert(csvData);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)], text: 'TwigaPOS Report CSV');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV report exported and shared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCustomReportDialog() async {
    DateTime? customStart = _startDate;
    DateTime? customEnd = _endDate;
    String reportType = 'Sales';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Generate Custom Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reportType,
                decoration: const InputDecoration(labelText: 'Report Type'),
                items: const [
                  DropdownMenuItem(value: 'Sales', child: Text('Sales Report')),
                  DropdownMenuItem(value: 'Products', child: Text('Products Report')),
                  DropdownMenuItem(value: 'Finance', child: Text('Finance Report')),
                  DropdownMenuItem(value: 'Customers', child: Text('Customers Report')),
                ],
                onChanged: (val) => setState(() => reportType = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(customStart!)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: customStart!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => customStart = picked);
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(customEnd!)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: customEnd!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => customEnd = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _startDate = customStart!;
                  _endDate = customEnd!;
                });
                Navigator.pop(context);
                _loadReportData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$reportType report generated for custom period')),
                );
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/'); } },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showCustomReportDialog,
            tooltip: 'Custom Report',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  _exportReportToPDF();
                  break;
                case 'csv':
                  _exportReportToCSV();
                  break;
                case 'share':
                  _exportReportToPDF();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'share', child: Text('Share Report')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.trending_up)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
            Tab(text: 'Finance', icon: Icon(Icons.account_balance)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildProductsTab(),
                _buildFinanceTab(),
                _buildCustomersTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomReportDialog,
        icon: const Icon(Icons.add_chart),
        label: const Text('New Report'),
      ),
    );
  }

  Widget _buildSalesTab() {
    final sales = _reportData['sales'] as List<SalesTransaction>? ?? [];
    final dailyRevenue = _reportData['dailyRevenue'] as Map<String, double>? ?? {};
    final dailyProfit = _reportData['dailyProfit'] as Map<String, double>? ?? {};

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todaySales = sales.where((s) =>
        s.timestamp.year == today.year &&
        s.timestamp.month == today.month &&
        s.timestamp.day == today.day).toList();

    final yesterdaySales = sales.where((s) =>
        s.timestamp.year == yesterday.year &&
        s.timestamp.month == yesterday.month &&
        s.timestamp.day == yesterday.day).toList();

    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.totalRevenue);
    final totalProfit = sales.fold<double>(0, (sum, sale) => sum + sale.totalProfit);

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Today\'s Sales',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${todaySales.fold<double>(0, (sum, s) => sum + s.totalRevenue).toStringAsFixed(2)}',
                  '${todaySales.length} transactions',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Yesterday\'s Sales',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${yesterdaySales.fold<double>(0, (sum, s) => sum + s.totalRevenue).toStringAsFixed(2)}',
                  '${yesterdaySales.length} transactions',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${totalRevenue.toStringAsFixed(2)}',
                  '${sales.length} transactions',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Profit',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${totalProfit.toStringAsFixed(2)}',
                  '${totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toStringAsFixed(1) : '0.0'}% margin',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

            // Revenue Chart
          _buildChartCard(
            'Revenue Trend',
            SizedBox(
              height: MediaQuery.of(context).size.width < 380 ? 140 : 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyRevenue.entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final days = date.difference(_startDate).inDays;
                        return FlSpot(days.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

            // Profit Chart
          _buildChartCard(
            'Profit Trend',
            SizedBox(
              height: MediaQuery.of(context).size.width < 380 ? 140 : 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyProfit.entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final days = date.difference(_startDate).inDays;
                        return FlSpot(days.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Sales
          _buildListCard(
            'Recent Sales',
            itemBuilder: (context, index) {
              final sale = sales[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.receipt, color: Colors.blue),
                ),
                title: Text('${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${sale.totalRevenue.toStringAsFixed(2)}'),
                subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp)),
                trailing: Text('${sale.quantity} items'),
              );
            },
            itemCount: sales.length > 10 ? 10 : sales.length,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final topProducts = _reportData['topProducts'] as List<dynamic>? ?? [];
    final lowTurnover = _reportData['lowTurnover'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best Sellers
          _buildListCard(
            'Best Sellers',
            itemBuilder: (context, index) {
              final product = topProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(product.productName),
                subtitle: Text('${product.totalSold} sold â€¢ ${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${product.totalRevenue.toStringAsFixed(2)} revenue'),
                trailing: Text('${product.marginPercentage.toStringAsFixed(1)}%'),
              );
            },
            itemCount: topProducts.length > 10 ? 10 : topProducts.length,
          ),

          const SizedBox(height: 24),

          // Low Turnover Products
          _buildListCard(
            'Low Turnover Products',
            itemBuilder: (context, index) {
              final product = lowTurnover[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                title: Text(product.productName),
                subtitle: Text('${product.totalSold} sold â€¢ ${product.turnoverRate.toStringAsFixed(2)} turnover rate'),
                trailing: Text('${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${product.totalRevenue.toStringAsFixed(2)}'),
              );
            },
            itemCount: lowTurnover.length > 10 ? 10 : lowTurnover.length,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab() {
    final transactions =
        _reportData['financeTransactions'] as List<dynamic>? ?? [];

    final expenses = transactions
        .where((t) =>
            t is Transaction &&
            t.type == TransactionType.expense)
        .toList();
    final income = transactions
        .where(
            (t) => t is Transaction && t.type == TransactionType.income)
        .toList();

    final totalExpenses = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${totalIncome.toStringAsFixed(2)}',
                  '${income.length} transactions',
                  Icons.arrow_upward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${totalExpenses.toStringAsFixed(2)}',
                  '${expenses.length} transactions',
                  Icons.arrow_downward,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          _buildListCard(
            'Recent Transactions',
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isExpense = transaction is Transaction &&
                  transaction.type == TransactionType.expense;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isExpense ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  child: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(transaction.description),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
                trailing: Text(
                  '${!isExpense ? '+' : '-'}${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: !isExpense ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            itemCount: transactions.length > 20 ? 20 : transactions.length,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    final customers = _reportData['customers'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Summary
          _buildSummaryCard(
            'Total Customers',
            '${customers.length}',
            'Active customers',
            Icons.people,
            Colors.blue,
          ),

          const SizedBox(height: 24),

          // Customer List
          _buildListCard(
            'Customer List',
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(customer.name[0].toUpperCase()),
                ),
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? 'No phone'),
                trailing: Text('${customer.totalPurchases} purchases'),
              );
            },
            itemCount: customers.length > 20 ? 20 : customers.length,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: Responsive.getCardElevation(context),
      margin: Responsive.getCardMargin(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 380 ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: Responsive.getCardElevation(context),
      margin: Responsive.getCardMargin(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 380 ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(
    String title, {
    List<Widget>? items,
    Widget Function(BuildContext, int)? itemBuilder,
    int? itemCount,
  }) {
    return Card(
      elevation: Responsive.getCardElevation(context),
      margin: Responsive.getCardMargin(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 380 ? 12 : 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if ((items?.isEmpty ?? false) || (itemCount == 0))
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No data available'),
            )
          else if (itemBuilder != null && itemCount != null)
            SizedBox(
              height: 320,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            )
          else if (items != null)
            ...items,
        ],
      ),
    );
  }
}







