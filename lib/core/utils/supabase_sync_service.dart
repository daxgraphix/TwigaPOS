import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/billing/domain/entities/sales_transaction.dart';
import '../../features/billing/domain/entities/customer.dart';
import '../../features/finance/domain/entities/transaction.dart';

class SupabaseSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Sync products
  static Future<void> syncProducts(List<Product> products) async {
    try {
      // Convert products to JSON
      final productsJson = products.map((p) => p.toJson()).toList();

      // Upsert to Supabase
      await _supabase.from('products').upsert(productsJson);
    } catch (e) {
      throw Exception('Failed to sync products: $e');
    }
  }

  // Sync sales transactions
  static Future<void> syncSalesTransactions(List<SalesTransaction> transactions) async {
    try {
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      await _supabase.from('sales_transactions').upsert(transactionsJson);
    } catch (e) {
      throw Exception('Failed to sync sales transactions: $e');
    }
  }

  // Sync customers
  static Future<void> syncCustomers(List<Customer> customers) async {
    try {
      final customersJson = customers.map((c) => c.toJson()).toList();
      await _supabase.from('customers').upsert(customersJson);
    } catch (e) {
      throw Exception('Failed to sync customers: $e');
    }
  }

  // Sync financial transactions
  static Future<void> syncFinancialTransactions(List<Transaction> transactions) async {
    try {
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      await _supabase.from('financial_transactions').upsert(transactionsJson);
    } catch (e) {
      throw Exception('Failed to sync financial transactions: $e');
    }
  }

  // Download products from Supabase
  static Future<List<Product>> downloadProducts() async {
    try {
      final response = await _supabase.from('products').select();
      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Failed to download products: $e');
    }
  }

  // Download sales transactions from Supabase
  static Future<List<SalesTransaction>> downloadSalesTransactions() async {
    try {
      final response = await _supabase.from('sales_transactions').select();
      return (response as List).map((t) => SalesTransaction.fromJson(t)).toList();
    } catch (e) {
      throw Exception('Failed to download sales transactions: $e');
    }
  }

  // Download customers from Supabase
  static Future<List<Customer>> downloadCustomers() async {
    try {
      final response = await _supabase.from('customers').select();
      return (response as List).map((c) => Customer.fromJson(c)).toList();
    } catch (e) {
      throw Exception('Failed to download customers: $e');
    }
  }

  // Download financial transactions from Supabase
  static Future<List<Transaction>> downloadFinancialTransactions() async {
    try {
      final response = await _supabase.from('financial_transactions').select();
      return (response as List).map((t) => Transaction.fromJson(t)).toList();
    } catch (e) {
      throw Exception('Failed to download financial transactions: $e');
    }
  }

  // Full sync - upload all local data to Supabase
  static Future<void> uploadAllData({
    required List<Product> products,
    required List<SalesTransaction> salesTransactions,
    required List<Customer> customers,
    required List<Transaction> financialTransactions,
  }) async {
    try {
      await syncProducts(products);
      await syncSalesTransactions(salesTransactions);
      await syncCustomers(customers);
      await syncFinancialTransactions(financialTransactions);
    } catch (e) {
      throw Exception('Failed to upload all data: $e');
    }
  }

  // Full sync - download all data from Supabase and merge with local
  static Future<Map<String, dynamic>> downloadAllData() async {
    try {
      final products = await downloadProducts();
      final salesTransactions = await downloadSalesTransactions();
      final customers = await downloadCustomers();
      final financialTransactions = await downloadFinancialTransactions();

      return {
        'products': products,
        'salesTransactions': salesTransactions,
        'customers': customers,
        'financialTransactions': financialTransactions,
      };
    } catch (e) {
      throw Exception('Failed to download all data: $e');
    }
  }

  // Check connection to Supabase
  static Future<bool> checkConnection() async {
    try {
      await _supabase.from('products').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final response = await _supabase
          .from('sync_metadata')
          .select('last_sync')
          .single();

      final timestamp = response['last_sync'];
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  // Update last sync timestamp
  static Future<void> updateLastSyncTimestamp() async {
    try {
      await _supabase.from('sync_metadata').upsert({
        'id': 'main',
        'last_sync': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore errors for metadata updates
    }
  }
}