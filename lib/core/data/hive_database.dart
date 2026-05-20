import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/finance/domain/entities/transaction.dart';
import '../../features/finance/domain/entities/category.dart';
import '../../features/finance/domain/entities/account.dart';
import '../../features/finance/domain/entities/budget.dart';
import '../../features/finance/domain/entities/recurring_transaction.dart';
import '../../features/billing/domain/entities/sales_transaction.dart';
import '../../features/product/domain/entities/stock_movement.dart';
import '../../features/billing/domain/entities/customer.dart';
import '../../features/billing/domain/entities/customer_transaction.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String transactionBoxName = 'transactions';
  static const String categoryBoxName = 'categories';
  static const String accountBoxName = 'accounts';
  static const String budgetBoxName = 'budgets';
  static const String recurringTransactionBoxName = 'recurring_transactions';
  static const String salesTransactionBoxName = 'sales_transactions';
  static const String stockMovementBoxName = 'stock_movements';
  static const String customerBoxName = 'customers';
  static const String customerTransactionBoxName = 'customer_transactions';
  static const String plannerEventsBoxName = 'planner_events';
  static const String plannerNotesBoxName = 'planner_notes';

  static Future<void> init() async {
    // Aggressively clean stale lock files (common cause of PathAccessException on Windows)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entities = Directory(dir.path).listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.lock')) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}

    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(RecurringIntervalAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(AccountTypeAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(BudgetPeriodAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(RecurringTransactionAdapter());
    Hive.registerAdapter(SalesTransactionAdapter());
    Hive.registerAdapter(MovementTypeAdapter());
    Hive.registerAdapter(StockMovementAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(CustomerTransactionTypeAdapter());
    Hive.registerAdapter(CustomerTransactionAdapter());

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<Transaction>(transactionBoxName);
    await Hive.openBox<Category>(categoryBoxName);
    await Hive.openBox<Account>(accountBoxName);
    await Hive.openBox<Budget>(budgetBoxName);
    await Hive.openBox<RecurringTransaction>(recurringTransactionBoxName);
    await Hive.openBox<SalesTransaction>(salesTransactionBoxName);
    await Hive.openBox<StockMovement>(stockMovementBoxName);
    await Hive.openBox<Customer>(customerBoxName);
    await Hive.openBox<CustomerTransaction>(customerTransactionBoxName);
    await Hive.openBox(plannerEventsBoxName);
    await Hive.openBox(plannerNotesBoxName);

    await _addDefaultData();
  }

  static Future<void> _addDefaultData() async {
    final categoryBox = HiveDatabase.categoryBox;
    if (categoryBox.isEmpty) {
      final categories = [
        Category(id: '1', name: 'Food', colorValue: 0xFFFF6B6B, iconName: 'food'),
        Category(id: '2', name: 'Transport', colorValue: 0xFF4ECDC4, iconName: 'transport'),
        Category(id: '3', name: 'Entertainment', colorValue: 0xFF45B7D1, iconName: 'entertainment'),
        Category(id: '4', name: 'Shopping', colorValue: 0xFFF9CA24, iconName: 'shopping'),
        Category(id: '5', name: 'Salary', colorValue: 0xFF6C5CE7, iconName: 'salary'),
        Category(id: '6', name: 'Investment', colorValue: 0xFF00B894, iconName: 'investment'),
        Category(id: '7', name: 'Other', colorValue: 0xFFA29BFE, iconName: 'other'),
      ];
      for (final c in categories) {
        await categoryBox.put(c.id, c);
      }
    }
    final accountBox = HiveDatabase.accountBox;
    if (accountBox.isEmpty) {
      final accounts = [
        Account(id: '1', name: 'Main Account', type: AccountType.checking, balance: 0.0),
      ];
      for (final a in accounts) {
        await accountBox.put(a.id, a);
      }
    }
  }

  // Box property getters
  static Box<ProductModel> get productBox => Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<Transaction> get transactionBox => Hive.box<Transaction>(transactionBoxName);
  static Box<Category> get categoryBox => Hive.box<Category>(categoryBoxName);
  static Box<Account> get accountBox => Hive.box<Account>(accountBoxName);
  static Box<Budget> get budgetBox => Hive.box<Budget>(budgetBoxName);
  static Box<RecurringTransaction> get recurringTransactionBox =>
      Hive.box<RecurringTransaction>(recurringTransactionBoxName);
  static Box<SalesTransaction> get salesTransactionBox =>
      Hive.box<SalesTransaction>(salesTransactionBoxName);
  static Box<StockMovement> get stockMovementBox =>
      Hive.box<StockMovement>(stockMovementBoxName);
  static Box<Customer> get customerBox => Hive.box<Customer>(customerBoxName);
  static Box<CustomerTransaction> get customerTransactionBox =>
      Hive.box<CustomerTransaction>(customerTransactionBoxName);
  static Box get plannerEventsBox => Hive.box(plannerEventsBoxName);
  static Box get plannerNotesBox => Hive.box(plannerNotesBoxName);

  // ──── Serialization helper ────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(Object? v) {
    final m = <String, dynamic>{};
    void put(String k, dynamic val) => m[k] = val;

    if (v is ProductModel) {
      put('json', v.toJson());
    } else if (v is ShopModel) {
      put('json', v.toJson());
    } else if (v is SalesTransaction) {
      put('json', v.toJson());
    } else if (v is Customer) {
      put('json', v.toJson());
    } else if (v is Transaction) {
      put('json', v.toJson());
    } else if (v is CustomerTransaction) {
      put('id', v.id);
      put('customerId', v.customerId);
      put('type', v.type.name);
      put('amount', v.amount);
      put('previousBalance', v.previousBalance);
      put('newBalance', v.newBalance);
      put('timestamp', v.timestamp.toIso8601String());
      put('reference', v.reference);
      put('notes', v.notes);
    } else if (v is Category) {
      put('id', v.id); put('name', v.name);
      put('colorValue', v.colorValue); put('iconName', v.iconName);
    } else if (v is Account) {
      put('id', v.id); put('name', v.name);
      put('type', v.type.name); put('balance', v.balance); put('currency', v.currency);
    } else if (v is Budget) {
      put('id', v.id); put('name', v.name); put('amount', v.amount);
      put('categoryId', v.categoryId); put('period', v.period.name);
      put('startDate', v.startDate.toIso8601String());
      put('endDate', v.endDate?.toIso8601String());
      put('spent', v.spent); put('limitAlertThreshold', v.limitAlertThreshold);
    } else if (v is RecurringTransaction) {
      put('id', v.id); put('description', v.description); put('amount', v.amount);
      put('interval', v.interval.name); put('type', v.type.name);
      put('categoryId', v.categoryId); put('accountId', v.accountId);
      put('startDate', v.startDate.toIso8601String());
      put('endDate', v.endDate?.toIso8601String());
      put('isActive', v.isActive);
    } else if (v is StockMovement) {
      put('id', v.id); put('productId', v.productId);
      put('type', v.type.name); put('quantity', v.quantity);
      put('previousStock', v.previousStock); put('newStock', v.newStock);
      put('timestamp', v.timestamp.toIso8601String());
      put('reference', v.reference); put('notes', v.notes);
    } else if (v is Map) {
      return Map<String, dynamic>.from(v);
    } else {
      put('value', v.toString());
    }
    return m;
  }

  static Map<String, dynamic> _boxToMap(Box box) {
    final out = <String, dynamic>{};
    for (final key in box.keys) {
      out[key.toString()] = _toMap(box.get(key));
    }
    return out;
  }

  // ──── Backup / Export ─────────────────────────────────────────────────────

  static Future<String> exportAllData() async {
    final data = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'boxes': <String, dynamic>{
        productBoxName: _boxToMap(productBox),
        shopBoxName: _boxToMap(shopBox),
        settingsBoxName: _boxToMap(settingsBox),
        transactionBoxName: _boxToMap(transactionBox),
        categoryBoxName: _boxToMap(categoryBox),
        accountBoxName: _boxToMap(accountBox),
        budgetBoxName: _boxToMap(budgetBox),
        recurringTransactionBoxName: _boxToMap(recurringTransactionBox),
        salesTransactionBoxName: _boxToMap(salesTransactionBox),
        stockMovementBoxName: _boxToMap(stockMovementBox),
        customerBoxName: _boxToMap(customerBox),
        customerTransactionBoxName: _boxToMap(customerTransactionBox),
        plannerEventsBoxName: _boxToMap(plannerEventsBox),
        plannerNotesBoxName: _boxToMap(plannerNotesBox),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ──── Restore / Import ────────────────────────────────────────────────────

   static Future<void> importAllData(String jsonString) async {
     final decoded = jsonDecode(jsonString);
     final data = decoded is Map
         ? Map<String, dynamic>.from(decoded)
         : <String, dynamic>{};
     final raw = (data['boxes'] as Map?) ?? data;
     final boxes = Map<String, dynamic>.from(raw);
    await _clearAllBoxes();
    await _populateBoxes(boxes);
  }

  static Future<void> _clearAllBoxes() async {
    await Future.wait([
      productBox.clear(),
      transactionBox.clear(),
      customerBox.clear(),
      categoryBox.clear(),
      accountBox.clear(),
      budgetBox.clear(),
      recurringTransactionBox.clear(),
      salesTransactionBox.clear(),
      stockMovementBox.clear(),
      customerTransactionBox.clear(),
      plannerEventsBox.clear(),
      plannerNotesBox.clear(),
    ]);
  }

  static Future<void> _populateBoxes(Map<String, dynamic> boxes) async {
    // Products
    for (final item in (boxes[productBoxName] as List?) ?? const []) {
      await productBox.add(ProductModel.fromJson(item as Map<String, dynamic>));
    }
    // Shop
    for (final item in (boxes[shopBoxName] as List?) ?? const []) {
      await shopBox.add(ShopModel.fromJson(item as Map<String, dynamic>));
    }
    // Settings (KV)
    final settings = (boxes[settingsBoxName] as Map?) ?? const {};
    await settingsBox.clear();
    for (final e in settings.entries) {
      await settingsBox.put(e.key, e.value);
    }
    // Transactions
    for (final item in (boxes[transactionBoxName] as List?) ?? const []) {
      await transactionBox.add(Transaction.fromJson(item as Map<String, dynamic>));
    }
    // Categories
    for (final item in (boxes[categoryBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await categoryBox.add(Category(
        id: m['id'] as String, name: m['name'] as String,
        colorValue: (m['colorValue'] as num).toInt(),
        iconName: m['iconName'] as String,
      ));
    }
    // Accounts
    for (final item in (boxes[accountBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await accountBox.add(Account(
        id: m['id'] as String, name: m['name'] as String,
        type: AccountType.values.firstWhere((e) => e.name == m['type'],
            orElse: () => AccountType.checking),
        balance: (m['balance'] as num).toDouble(),
        currency: (m['currency'] as String?) ?? 'TZS',
      ));
    }
    // Budgets
    for (final item in (boxes[budgetBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await budgetBox.add(Budget(
        id: m['id'] as String, name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['categoryId'] as String,
        period: BudgetPeriod.values
            .firstWhere((e) => e.name == m['period'], orElse: () => BudgetPeriod.monthly),
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        spent: (m['spent'] as num?)?.toDouble() ?? 0.0,
        limitAlertThreshold: (m['limitAlertThreshold'] as num?)?.toDouble() ?? 0.9,
      ));
    }
    // Recurring transactions
    for (final item in (boxes[recurringTransactionBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await recurringTransactionBox.add(RecurringTransaction(
        id: m['id'] as String, description: m['description'] as String,
        amount: (m['amount'] as num).toDouble(),
        interval: RecurringInterval.values
            .firstWhere((e) => e.name == m['interval'], orElse: () => RecurringInterval.monthly),
        type: TransactionType.values
            .firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.expense),
        categoryId: m['categoryId'] as String, accountId: m['accountId'] as String,
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        isActive: m['isActive'] as bool? ?? true,
      ));
    }
    // Sales transactions
    for (final item in (boxes[salesTransactionBoxName] as List?) ?? const []) {
      await salesTransactionBox.add(SalesTransaction.fromJson(item as Map<String, dynamic>));
    }
    // Stock movements
    for (final item in (boxes[stockMovementBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await stockMovementBox.add(StockMovement(
        id: m['id'] as String, productId: m['productId'] as String,
        type: MovementType.values
            .firstWhere((e) => e.name == m['type'], orElse: () => MovementType.adjustment),
        quantity: (m['quantity'] as num).toInt(),
        previousStock: (m['previousStock'] as num).toInt(),
        newStock: (m['newStock'] as num).toInt(),
        timestamp: DateTime.parse(m['timestamp'] as String),
        reference: m['reference'] as String, notes: (m['notes'] as String?) ?? '',
      ));
    }
    // Customer transactions
    for (final item in (boxes[customerTransactionBoxName] as List?) ?? const []) {
      final m = item as Map<String, dynamic>;
      await customerTransactionBox.add(CustomerTransaction(
        id: m['id'] as String, customerId: m['customerId'] as String,
        type: CustomerTransactionType.values
            .firstWhere((e) => e.name == m['type'], orElse: () => CustomerTransactionType.creditSale),
        amount: (m['amount'] as num).toDouble(),
        previousBalance: (m['previousBalance'] as num).toDouble(),
        newBalance: (m['newBalance'] as num).toDouble(),
        timestamp: DateTime.parse(m['timestamp'] as String),
        reference: m['reference'] as String, notes: (m['notes'] as String?) ?? '',
      ));
    }
    // Planner events
    for (final item in (boxes[plannerEventsBoxName] as List?) ?? const []) {
      await plannerEventsBox.add(item is Map
          ? <String, dynamic>{}
          : <String, dynamic>{'v': item.toString()});
    }
    // Planner notes
    for (final item in (boxes[plannerNotesBoxName] as List?) ?? const []) {
      await plannerNotesBox.add(item.toString());
    }
  }

  // ──── Archive (typed snapshot) ─────────────────────────────────────────────

   static Future<Map<String, List<Map<String, dynamic>>>> archive() async {
     return <String, List<Map<String, dynamic>>>{
       'products':
           productBox.values.map((e) => e.toJson()).toList(),
       'transactions':
           transactionBox.values.map((e) => e.toJson()).toList(),
       'customers':
           customerBox.values.map((e) => e.toJson()).toList(),
       'salesTransactions':
           salesTransactionBox.values.map((e) => e.toJson()).toList(),
      'categories':
          categoryBox.values.map<Map<String, dynamic>>((c) {
            return <String, dynamic>{
              'id': c.id, 'name': c.name,
              'colorValue': c.colorValue, 'iconName': c.iconName,
            };
          }).toList(),
      'accounts':
          accountBox.values.map<Map<String, dynamic>>((a) {
            return <String, dynamic>{
              'id': a.id, 'name': a.name,
              'type': a.type.name, 'balance': a.balance, 'currency': a.currency,
            };
          }).toList(),
      'budgets':
          budgetBox.values.map<Map<String, dynamic>>((b) {
            return <String, dynamic>{
              'id': b.id, 'name': b.name, 'amount': b.amount,
              'categoryId': b.categoryId, 'period': b.period.name, 'spent': b.spent,
            };
          }).toList(),
      'recurringTransactions':
          recurringTransactionBox.values.map<Map<String, dynamic>>((r) {
            return <String, dynamic>{
              'id': r.id, 'description': r.description, 'amount': r.amount,
              'interval': r.interval.name, 'type': r.type.name, 'isActive': r.isActive,
            };
          }).toList(),
      'stockMovements':
          stockMovementBox.values.map<Map<String, dynamic>>((s) {
            return <String, dynamic>{
              'id': s.id, 'productId': s.productId, 'type': s.type.name,
              'quantity': s.quantity,
              'timestamp': s.timestamp.toIso8601String(),
            };
          }).toList(),
      'customerTransactions':
          customerTransactionBox.values.map<Map<String, dynamic>>((c) {
            return <String, dynamic>{
              'id': c.id, 'customerId': c.customerId, 'type': c.type.name,
              'amount': c.amount,
              'timestamp': c.timestamp.toIso8601String(),
            };
          }).toList(),
    };
  }
}
