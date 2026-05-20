import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../billing/domain/entities/customer.dart';
import '../../../billing/domain/repositories/customer_repository.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customerRepo = context.read<CustomerRepository>();
      final result = await customerRepo.getCustomers();

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load customers: $failure')),
          );
        },
        (customers) {
          setState(() {
            _customers = customers;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery) ||
             customer.phone.toLowerCase().contains(_searchQuery) ||
             customer.email.toLowerCase().contains(_searchQuery);
    }).toList();

    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.event_note),
              onPressed: () => context.push('/planner'),
              tooltip: 'Planner & Notes',
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/customers/add'),
            tooltip: 'Add Customer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context)),
              child: GridView.count(
                crossAxisCount: Responsive.getGridCrossAxisCount(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.5 : 1.4,
                children: [
                  _buildSummaryCard(
                    'Total Customers',
                    _customers.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    'Active Customers',
                    _customers.where((c) => c.isActive).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    'Outstanding Debt',
                    '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${_customers.fold(0.0, (sum, c) => sum + c.currentBalance).toStringAsFixed(0)}',
                    Icons.account_balance,
                    Colors.orange,
                  ),
                  _buildSummaryCard(
                    'Avg Balance',
                    _customers.isEmpty ? '0' : '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${(_customers.fold(0.0, (sum, c) => sum + c.currentBalance) / _customers.length).toStringAsFixed(0)}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCustomers,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredCustomers.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
            const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isEmpty ? 'No customers found' : 'No customers match your search',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                          padding: EdgeInsets.only(
                            left: Responsive.getPadding(context),
                            right: Responsive.getPadding(context),
                            bottom: MediaQuery.of(context).padding.bottom + (isDesktop ? 60 : 90),
                          ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return Card(
                                elevation: Responsive.getCardElevation(context),
                                margin: Responsive.getCardMargin(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => _showCustomerDetails(customer),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: isDesktop
                                        ? _buildDesktopCustomerRow(customer)
                                        : _buildMobileCustomerRow(customer),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/add'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final isSmallPhone = MediaQuery.of(context).size.width < 380;

    return Card(
      elevation: Responsive.getCardElevation(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallPhone ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallPhone ? 4 : 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isSmallPhone ? 16 : 20),
            ),
            SizedBox(height: isSmallPhone ? 3 : 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmallPhone ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallPhone ? 9 : 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Phone', customer.phone),
              _buildDetailRow('Email', customer.email.isNotEmpty ? customer.email : 'Not provided'),
              _buildDetailRow('Credit Limit', '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${customer.creditLimit.toStringAsFixed(2)}'),
              _buildDetailRow('Current Balance', '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${customer.currentBalance.toStringAsFixed(2)}'),
              _buildDetailRow('Available Credit', '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${customer.availableCredit.toStringAsFixed(2)}'),
              _buildDetailRow('Status', customer.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(customer.createdAt)),
              _buildDetailRow('Last Transaction', _formatDate(customer.lastTransaction)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _viewCustomerTransactions(Customer customer) {
    context.push('/customers/transactions/${customer.id}');
  }

  void _editCustomer(Customer customer) {
    context.push('/customers/edit/${customer.id}');
  }

  void _toggleCustomerStatus(Customer customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer ${customer.isActive ? 'deactivated' : 'activated'}'),
        backgroundColor: customer.isActive ? Colors.red : Colors.green,
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getDebtStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.paid:
        return Colors.green;
      case DebtStatus.good:
        return Colors.blue;
      case DebtStatus.warning:
        return Colors.orange;
      case DebtStatus.overdue:
        return Colors.red;
    }
  }

  String _getDebtStatusText(DebtStatus status) {
    switch (status) {
      case DebtStatus.paid:
        return 'Paid';
      case DebtStatus.good:
        return 'Good';
      case DebtStatus.warning:
        return 'Warning';
      case DebtStatus.overdue:
        return 'Overdue';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDesktopCustomerRow(Customer customer) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getDebtStatusColor(customer.debtStatus).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              customer.name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase(),
              style: TextStyle(
                color: _getDebtStatusColor(customer.debtStatus),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: customer.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                customer.phone,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            customer.email.isNotEmpty ? customer.email : 'No email',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${customer.currentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: customer.currentBalance > 0 ? Colors.red : Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDebtStatusColor(customer.debtStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDebtStatusText(customer.debtStatus),
                  style: TextStyle(color: _getDebtStatusColor(customer.debtStatus), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_transactions':
                _viewCustomerTransactions(customer);
                break;
              case 'edit':
                _editCustomer(customer);
                break;
              case 'toggle_status':
                _toggleCustomerStatus(customer);
                break;
              case 'delete':
                _deleteCustomer(customer);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view_transactions', child: Text('View Transactions')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'toggle_status', child: Text(customer.isActive ? 'Deactivate' : 'Activate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileCustomerRow(Customer customer) {
    final isSmallPhone = MediaQuery.of(context).size.width < 380;

    return Row(
      children: [
        Container(
          width: isSmallPhone ? 42 : 48,
          height: isSmallPhone ? 42 : 48,
          decoration: BoxDecoration(
            color: _getDebtStatusColor(customer.debtStatus).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isSmallPhone ? 21 : 24),
          ),
          child: Center(
            child: Text(
              customer.name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase(),
              style: TextStyle(
                color: _getDebtStatusColor(customer.debtStatus),
                fontWeight: FontWeight.bold,
                fontSize: isSmallPhone ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallPhone ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: isSmallPhone ? 14 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: customer.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                customer.phone,
                style: TextStyle(fontSize: isSmallPhone ? 12 : 13, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (customer.email.isNotEmpty)
                Text(
                  customer.email,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppTheme.getCurrencySymbol(Hive.box('settings').get('selectedCurrency', defaultValue: 'TZS'))}${customer.currentBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isSmallPhone ? 13 : 15,
                fontWeight: FontWeight.bold,
                color: customer.currentBalance > 0 ? Colors.red : Colors.green,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 6 : 8,
                vertical: isSmallPhone ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: _getDebtStatusColor(customer.debtStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getDebtStatusText(customer.debtStatus),
                style: TextStyle(
                  color: _getDebtStatusColor(customer.debtStatus),
                  fontSize: isSmallPhone ? 10 : 11,
                ),
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_transactions':
                _viewCustomerTransactions(customer);
                break;
              case 'edit':
                _editCustomer(customer);
                break;
              case 'toggle_status':
                _toggleCustomerStatus(customer);
                break;
              case 'delete':
                _deleteCustomer(customer);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view_transactions', child: Text('View Transactions')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'toggle_status', child: Text(customer.isActive ? 'Deactivate' : 'Activate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    );
  }
}
