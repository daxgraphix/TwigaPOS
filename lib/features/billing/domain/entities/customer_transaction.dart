import 'package:hive/hive.dart';

part 'customer_transaction.g.dart';

@HiveType(typeId: 24)
enum CustomerTransactionType {
  @HiveField(0)
  creditSale, // Sale on credit
  @HiveField(1)
  payment, // Customer payment
  @HiveField(2)
  adjustment, // Manual adjustment
  @HiveField(3)
  writeOff, // Debt write-off
}

@HiveType(typeId: 25)
class CustomerTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final CustomerTransactionType type;

  @HiveField(3)
  final double amount; // Positive for credits/charges, negative for payments

  @HiveField(4)
  final double previousBalance;

  @HiveField(5)
  final double newBalance;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String reference; // Sale ID, payment receipt, etc.

  @HiveField(8)
  final String notes;

  CustomerTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.timestamp,
    required this.reference,
    this.notes = '',
  });

  @override
  String toString() {
    return 'CustomerTransaction(id: $id, customer: $customerId, type: $type, amount: $amount, balance: $newBalance)';
  }
}