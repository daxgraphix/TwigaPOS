import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../finance/domain/entities/transaction.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  @override
  void initState() {
    super.initState();
    // Load initial operations data
    _loadOperationsData();
  }

  void _toggleShift(BuildContext context) {
    final settingsBox = HiveDatabase.settingsBox;
    final newActive = !(settingsBox.get('shiftActive', defaultValue: false) as bool);
    settingsBox.put('shiftActive', newActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newActive ? 'Shift started' : 'Shift ended'),
        backgroundColor: newActive ? Colors.green : Colors.orange,
      ),
    );
    // Also refresh the UI to show updated state
    setState(() {});
  }

  void _showCashDropDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cash Drop'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'TSh ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) return;
              final txn = Transaction(
                id: 'cashdrop_${DateTime.now().millisecondsSinceEpoch}',
                description: 'Cash Drop',
                amount: amount,
                date: DateTime.now(),
                categoryId: 'cash-drop',
                accountId: '',
                type: TransactionType.expense,
              );
              HiveDatabase.transactionBox.add(txn);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cash drop of TSh $amount recorded')),
              );
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _loadOperationsData() {
    // Refresh shift data from Hive
    if (mounted) {
      setState(() {}); // Trigger rebuild to update UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/'); } },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOperationsData(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.all(Responsive.getPadding(context)).copyWith(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Shift Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Card(
                elevation: Responsive.getCardElevation(context),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ValueListenableBuilder<Box>(
                        valueListenable: HiveDatabase.settingsBox.listenable(),
                        builder: (context, box, _) {
                          final isShiftActive =
                              box.get('shiftActive', defaultValue: false) as bool;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isShiftActive
                                        ? Icons.play_circle_filled
                                        : Icons.pause_circle_filled,
                                    size: 48,
                                    color: isShiftActive
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isShiftActive
                                              ? 'Shift Active'
                                              : 'Shift Closed',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          isShiftActive
                                              ? 'Currently serving customers'
                                              : 'Ready to start new shift',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _toggleShift(context),
                                  icon: Icon(isShiftActive
                                      ? Icons.stop
                                      : Icons.play_arrow),
                                  label: Text(isShiftActive
                                      ? 'End Shift'
                                      : 'Start Shift'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isShiftActive
                                        ? Colors.red
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
               // Quick Actions - using simple Column + Row for reliability
               Column(
                 children: [
                   Row(
                     children: [
                       Expanded(child: _buildQuickActionCard('Cash Drop', Icons.money, AppTheme.primaryColor, () => _showCashDropDialog(context))),
                       const SizedBox(width: 12),
                       Expanded(child: _buildQuickActionCard('End of Day', Icons.assessment, AppTheme.primaryColor, () => context.push('/shift-report'))),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(child: _buildQuickActionCard('View Reports', Icons.bar_chart, AppTheme.primaryColor, () => context.go('/reports'))),
                       const SizedBox(width: 12),
                       Expanded(child: _buildQuickActionCard('Planner', Icons.event_note, AppTheme.primaryColor, () => context.push('/planner'))),
                     ],
                   ),
                 ],
               ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    final isSmallPhone = MediaQuery.of(context).size.width < 380;

    return Card(
      elevation: Responsive.getCardElevation(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isSmallPhone ? 26 : 32, color: color),
              SizedBox(height: isSmallPhone ? 6 : 8),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isSmallPhone ? 12 : 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

