import 'package:hive/hive.dart';
import 'transaction.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 18)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final RecurringInterval interval;

  @HiveField(4)
  final TransactionType type;

  @HiveField(5)
  final String categoryId;

  @HiveField(6)
  final String accountId;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime? endDate;

  @HiveField(9)
  final bool isActive;

  RecurringTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.interval,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });
}