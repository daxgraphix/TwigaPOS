import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/entities/user.dart';

class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
}

class SessionManager {
  static Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 45);

  static void startSessionRefresh(SupabaseClient client) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      try {
        final session = client.auth.currentSession;
        if (session != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            session.expiresAt! * 1000,
          );
          if (DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)))) {
            await client.auth.refreshSession();
          }
        }
      } catch (e) {
        // Handle refresh error - user may need to re-login
      }
    });
  }

  static void stopSessionRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}

class RoleBasedAccess {
  static const Map<String, List<UserRole>> _permissions = {
    'manage_users': [UserRole.admin],
    'manage_products': [UserRole.admin, UserRole.manager, UserRole.inventoryManager],
    'view_reports': [UserRole.admin, UserRole.manager],
    'process_sales': [UserRole.admin, UserRole.manager, UserRole.cashier],
    'manage_finance': [UserRole.admin, UserRole.manager],
  };

  static bool hasPermission(UserRole role, String permission) {
    return _permissions[permission]?.contains(role) ?? false;
  }

  static bool canManageUsers(UserRole role) => hasPermission(role, 'manage_users');
  static bool canManageProducts(UserRole role) => hasPermission(role, 'manage_products');
  static bool canViewReports(UserRole role) => hasPermission(role, 'view_reports');
  static bool canProcessSales(UserRole role) => hasPermission(role, 'process_sales');
  static bool canManageFinance(UserRole role) => hasPermission(role, 'manage_finance');
}
