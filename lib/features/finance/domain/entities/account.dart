import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 14)
enum AccountType {
  @HiveField(0)
  checking,
  @HiveField(1)
  savings,
  @HiveField(2)
  credit,
  @HiveField(3)
  investment,
}

@HiveType(typeId: 15)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final AccountType type;

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final String currency;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'TZS',
  });
}