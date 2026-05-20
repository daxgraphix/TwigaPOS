import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 13)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final String iconName;

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconName,
  });

  Color get color => Color(colorValue);

  IconData get icon => _getIconFromName(iconName);

  static IconData _getIconFromName(String name) {
    switch (name) {
      case 'food': return Icons.restaurant;
      case 'bills': return Icons.receipt;
      case 'health': return Icons.local_hospital;
      case 'education': return Icons.school;
      case 'shopping': return Icons.shopping_bag;
      case 'transport': return Icons.directions_car;
      case 'entertainment': return Icons.movie;
      case 'utilities': return Icons.lightbulb;
      case 'salary': return Icons.work;
      case 'investment': return Icons.trending_up;
      case 'funds': return Icons.account_balance_wallet;
      case 'stocks': return Icons.inventory;
      case 'other': return Icons.category;
      default: return Icons.category;
    }
  }
}