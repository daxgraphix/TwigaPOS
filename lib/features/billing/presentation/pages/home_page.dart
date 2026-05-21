import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/transaction_bloc.dart';
import '../../../finance/presentation/bloc/budget_cubit.dart';
import '../../../finance/presentation/bloc/account_cubit.dart';
import '../../../finance/presentation/bloc/report_cubit.dart';
import '../../../finance/domain/entities/transaction.dart';
import '../../../finance/domain/entities/account.dart';
import '../../../finance/domain/usecases/monthly_report_usecase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    @override
    void initState() {
      super.initState();
      // Load initial finance data using focused BLoCs/Cubits
      context.read<TransactionBloc>().add(LoadTransactionsEvent());
      context.read<AccountCubit>().loadAccounts();
      context.read<BudgetCubit>().loadBudgets();
      context.read<ReportCubit>().loadMonthlyReport(DateTime.now());

      // FinanceBloc â€” categories only (has a valid handler)
      context.read<FinanceBloc>().add(LoadCategoriesEvent());

      // Load shop details for the drawer header
      context.read<ShopBloc>().add(LoadShopEvent());

      // Generate recurring transactions
      _generateRecurringTransactions();
    }

  void _generateRecurringTransactions() {
    // Simple implementation: check if any recurring transactions need to generate transactions today
    // For demo, if there are recurring transactions, add a transaction if not already added today
    // In real app, this should be more sophisticated
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Quick Access Cards - Planner & Calendar, Notes, Operations, Reports (as requested)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildQuickCard('Planner & Calendar', Icons.event_note, () => context.push('/planner'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickCard('Notes', Icons.note, () => context.push('/planner'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildQuickCard('Operations', Icons.business_center, () => context.push('/operations'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickCard('Reports', Icons.bar_chart, () => context.push('/reports'))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                TransactionsTab(),
                ReportsTab(),
                AccountsTab(),
                BudgetsTab(),
                CategoriesTab(),
                PlannerTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        child: const Icon(Icons.menu),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Accounts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Budgets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note),
          label: 'Planner',
        ),
      ],
    );
  }

  Widget _buildQuickCard(String title, IconData icon, VoidCallback onTap) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isSmall ? 26 : 32, color: AppTheme.primaryColor),
              SizedBox(height: isSmall ? 6 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          BlocBuilder<ShopBloc, ShopState>(
            builder: (context, state) {
              String shopName = 'My Shop';
              if (state is ShopLoaded && state.shop.name.isNotEmpty) {
                shopName = state.shop.name;
              }
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                     const Text(
                       'Personal Finance Tracker',
                       style: TextStyle(
                         color: Colors.white70,
                         fontSize: 12,
                       ),
                     ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.green),
                  title: const Text('Transactions'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    setState(() => _selectedIndex = 0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.orange),
                  title: const Text('Reports'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    setState(() => _selectedIndex = 1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.purple),
                  title: const Text('Accounts'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    setState(() => _selectedIndex = 2);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
                  title: const Text('Budgets'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    setState(() => _selectedIndex = 3);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.indigo),
                  title: const Text('Categories'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    setState(() => _selectedIndex = 4);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.store, color: Colors.indigo),
                  title: const Text('Shop Details'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    context.push('/shop');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Settings'),
                  onTap: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/'); }
                    context.push('/settings');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'FinanceTracker v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionInitial || state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionLoaded) {
          if (state.transactions.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index == state.transactions.length) {
                  // Footer — Add Transaction button
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-transaction'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Transaction'),
                    ),
                  );
                }
                final transaction = state.transactions[index];
                final currency = Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS');
                final symbol = AppTheme.getCurrencySymbol(currency);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.type == TransactionType.expense
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      child: Icon(
                        transaction.type == TransactionType.expense
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: transaction.type == TransactionType.expense
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    title: Text(transaction.description,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
                    trailing: Text(
                      '$symbol${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaction.type == TransactionType.expense
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swap_horiz, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No transactions yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add your first expense or income',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-transaction'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                  ),
                ],
              ),
            );
          }
        }

        return const Center(child: Text('Error loading transactions'));
      },
    );
  }
}

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<ReportCubit>().loadMonthlyReport(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        // Month picker header — natural height, not in Expanded
        Widget monthHeader = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Select Month: ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                 onPressed: () async {
                   final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                   if (date != null && mounted) {
                     final selectedMonth = date;
                     setState(() {
                       _selectedMonth = selectedMonth;
                     });
                      context.read<ReportCubit>().loadMonthlyReport(selectedMonth);
                   }
              },
              child: Text('${_selectedMonth.month}/${_selectedMonth.year}'),
            ),
            ],
          ),
        );

        Widget reportBody;
        if (state is ReportInitial || state.isLoading) {
          reportBody = const Center(child: CircularProgressIndicator());
        } else if (state is ReportLoaded) {
          reportBody = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(state.report),
                const SizedBox(height: 24),
                const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildExpensePieChart(state.report),
                ),
                const SizedBox(height: 24),
                // Export/Share buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportReport(state.report),
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareReport(state.report),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          reportBody = const Center(child: Text('Error loading report'));
        }

        return Column(
          children: [
            monthHeader,
            Expanded(child: reportBody),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(MonthlyReport report) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('Income', report.totalIncome, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard('Expenses', report.totalExpenses, Colors.red),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard('Net', report.netIncome, report.netIncome >= 0 ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  Widget _buildCard(String title, double amount, Color color) {
    final currency = Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS');
    final symbol = AppTheme.getCurrencySymbol(currency);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$symbol${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart(MonthlyReport report) {
    final expenseTransactions = report.transactions.where((t) => t.type == TransactionType.expense).toList();
    final categoryTotals = <String, double>{};

    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.categoryId] = (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No expenses this month'));
    }

    final sections = categoryTotals.entries.map((entry) {
      final categoryName = _getCategoryName(entry.key);
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '$categoryName\n${entry.value.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      final financeState = context.read<FinanceBloc>().state;
      if (financeState is CategoriesLoaded) {
        final match = financeState.categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => throw Exception('not found'),
        );
        return match.name;
      }
    } catch (_) {}
    return categoryId;
  }

  Color _getCategoryColor(String categoryId) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
    return colors[categoryId.hashCode % colors.length];
  }

  Future<void> _exportReport(MonthlyReport report) async {
    try {
      final csv = StringBuffer();
      csv.writeln('Description,Category,Type,Amount,Date');

      for (final t in report.transactions) {
        csv.writeln('"${t.description}","${t.categoryId}",${t.type},${t.amount},${t.date.toIso8601String()}');
      }

      // Save to file (simplified - in production use path_provider and share)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported: ${report.transactions.length} transactions'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _shareReport(report),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareReport(MonthlyReport report) async {
    final summary = '''
Monthly Report - ${_selectedMonth.month}/${_selectedMonth.year}

Total Income: ${report.totalIncome}
Total Expenses: ${report.totalExpenses}
Net Income: ${report.netIncome}

Transactions: ${report.transactions.length}
''';

    // In production, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report ready to share:\n$summary')),
    );
  }
}

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        if (state is AccountInitial || state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountLoaded) {
          if (state.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No accounts yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add your first account',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/finance'),
                      icon: const Icon(Icons.add),
                      label: const Text('Manage Accounts'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.accounts.length,
            itemBuilder: (context, index) {
              final account = state.accounts[index];
              final currency = Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS');
              final symbol = AppTheme.getCurrencySymbol(currency);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      account.type == AccountType.checking
                          ? Icons.account_balance
                          : account.type == AccountType.savings
                              ? Icons.savings
                              : Icons.credit_card,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(account.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(account.type.name.toUpperCase()),
                  trailing: Text(
                    '$symbol${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );

        }

        return const Center(child: Text('Error loading accounts'));
      },
    );
  }
}

class BudgetsTab extends StatelessWidget {
  const BudgetsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        if (state is BudgetInitial || state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BudgetLoaded) {
          if (state.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No budgets yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create your first budget',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/budgets/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Budget'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.budgets.length,
            itemBuilder: (context, index) {
              final budget = state.budgets[index];
              final currency = Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS');
              final symbol = AppTheme.getCurrencySymbol(currency);
              final progress = budget.amount > 0 ? budget.spent / budget.amount : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      '${((progress) * 100).toInt()}%',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(budget.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spent: $symbol${budget.spent.toStringAsFixed(2)} / $symbol${budget.amount.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 1.0 ? Colors.red : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

        }

        return const Center(child: Text('Error loading budgets'));
      },
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is FinanceInitial || state is FinanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoriesLoaded) {
          if (state.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No categories yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add your first category',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<FinanceBloc>()
                            .add(LoadCategoriesEvent());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Categories will be available')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color,
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            },
          );

        }

        return const Center(child: Text('Error loading categories'));
      },
    );
  }
}

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _events = [];
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

    void _loadData() {
    final eventsBox = Hive.box('planner_events');
    final notesBox = Hive.box('planner_notes');

    if (eventsBox.isNotEmpty) {
      _events = eventsBox.values.map((raw) {
        if (raw is Map) return Map<String, dynamic>.from(raw);
        if (raw is Map<String, dynamic>) return raw;
        // HiveBox rehydration can return Map<dynamic, dynamic> — coerce
        return Map<String, dynamic>.from(Map<dynamic, dynamic>.from(raw as Map));
      }).toList();
    }
    if (notesBox.isNotEmpty) {
      _notes = notesBox.values.cast<String>().toList();
    }
    setState(() {});
  }

  void _saveEvents() {
    final eventsBox = Hive.box('planner_events');
    eventsBox.clear();
    for (var event in _events) {
      eventsBox.add(event);
    }
  }

  void _saveNotes() {
    final notesBox = Hive.box('planner_notes');
    notesBox.clear();
    for (var note in _notes) {
      notesBox.add(note);
    }
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Event title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _events.add({
                      'date': _selectedDay?.toIso8601String(),
                      'title': titleController.text,
                    });
                  });
                  _saveEvents();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController noteController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write your note...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.isNotEmpty) {
                  setState(() {
                    _notes.add(noteController.text);
                  });
                  _saveNotes();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _events
        .where((e) =>
            e['date'] != null &&
            isSameDay(DateTime.parse(e['date'] as String), _selectedDay ?? _focusedDay))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addEvent,
                        tooltip: 'Add Event',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                     onPageChanged: (focusedDay) {
                       _focusedDay = focusedDay;
                     },
                   ),
                  ),
                 ],
               ),
             ),
           ),
          const SizedBox(height: 16),

          // Events Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today\'s Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addEvent,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dayEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No events for this day', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...dayEvents.map((event) => ListTile(
                          leading: const Icon(Icons.event, color: Colors.blue),
                          title: Text(event['title'] ?? ''),
                          subtitle: Text(event['date']?.toString().split('T').first ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _events.remove(event);
                              });
                              _saveEvents();
                            },
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quick Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addNote,
                        icon: const Icon(Icons.note_add, size: 18),
                        label: const Text('Add Note'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No notes yet', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ..._notes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final note = entry.value;
                      return ListTile(
                        leading: const Icon(Icons.note, color: Colors.orange),
                        title: Text(note),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _notes.removeAt(index);
                            });
                            _saveNotes();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


