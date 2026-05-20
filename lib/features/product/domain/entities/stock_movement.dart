import 'package:hive/hive.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 21)
enum MovementType {
  @HiveField(0)
  procurement, // Adding stock via purchase/procurement
  @HiveField(1)
  sale, // Reducing stock via sale
  @HiveField(2)
  adjustment, // Manual stock adjustment
  @HiveField(3)
  returnIn, // Customer returns
  @HiveField(4)
  returnOut, // Returns to supplier
}

@HiveType(typeId: 22)
class StockMovement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final MovementType type;

  @HiveField(3)
  final int quantity; // Positive for additions, negative for reductions

  @HiveField(4)
  final int previousStock;

  @HiveField(5)
  final int newStock;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String reference; // Sale ID, procurement ID, etc.

  @HiveField(8)
  final String notes; // Optional notes

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.timestamp,
    required this.reference,
    this.notes = '',
  });

  @override
  String toString() {
    return 'StockMovement(id: $id, product: $productId, type: $type, quantity: $quantity, newStock: $newStock)';
  }
}