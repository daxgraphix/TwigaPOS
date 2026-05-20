import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth & Setup
import 'package:twigapos/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:twigapos/features/auth/presentation/pages/auth_page.dart';
import 'package:twigapos/features/shop/presentation/pages/customer_shop_setup_page.dart';
import 'package:twigapos/features/settings/presentation/pages/pin_lock_screen.dart';

// Shop Details
import 'package:twigapos/features/shop/presentation/pages/shop_details_page.dart';

// Add Transaction
import 'package:twigapos/features/finance/presentation/pages/add_transaction_page.dart';

// Main Pages
import 'package:twigapos/features/billing/presentation/pages/dashboard_page.dart';
import 'package:twigapos/features/billing/presentation/pages/new_sale_page.dart';
import 'package:twigapos/features/billing/presentation/pages/reports_page.dart';
import 'package:twigapos/features/billing/presentation/pages/home_page.dart';
import 'package:twigapos/features/billing/presentation/pages/checkout_page.dart';
import 'package:twigapos/features/billing/presentation/pages/settings_page.dart';
import 'package:twigapos/features/billing/presentation/pages/operations_page.dart';
import 'package:twigapos/features/planner/presentation/pages/planner_page.dart';
import 'package:twigapos/features/billing/presentation/pages/about_app_page.dart';
import 'package:twigapos/features/billing/presentation/pages/terms_conditions_page.dart';
import 'package:twigapos/features/billing/presentation/pages/privacy_policy_page.dart';
import 'package:twigapos/features/billing/presentation/pages/help_support_page.dart';
import 'package:twigapos/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:twigapos/features/billing/presentation/pages/invoice_detail_page.dart';
import 'package:twigapos/features/billing/presentation/pages/shift_report_page.dart';

// Finance
import 'package:twigapos/features/finance/presentation/pages/budget_list_page.dart';
import 'package:twigapos/features/finance/presentation/pages/edit_budget_page.dart';

// Product
import 'package:twigapos/features/product/presentation/pages/product_list_page.dart';
import 'package:twigapos/features/product/presentation/pages/add_product_page.dart';
import 'package:twigapos/features/product/presentation/pages/edit_product_page.dart';

// Customer
import 'package:twigapos/features/billing/presentation/pages/customer_list_page.dart';
import 'package:twigapos/features/billing/presentation/pages/add_customer_page.dart';
import 'package:twigapos/features/billing/presentation/pages/edit_customer_page.dart';
import 'package:twigapos/features/billing/presentation/pages/customer_transactions_page.dart';

// User
import 'package:twigapos/features/auth/presentation/pages/user_list_page.dart';
import 'package:twigapos/features/auth/presentation/pages/add_user_page.dart';
import 'package:twigapos/features/auth/presentation/pages/edit_user_page.dart';

// Entities
import 'package:twigapos/features/finance/domain/entities/budget.dart';
import 'package:twigapos/features/product/domain/entities/product.dart';
import 'package:twigapos/features/billing/domain/entities/customer.dart';
import 'package:twigapos/features/auth/domain/entities/user.dart';

// Navigation Shell
import 'package:twigapos/core/widgets/main_navigation_shell.dart';

GoRouter createRouter(ValueNotifier<bool> authStateNotifier) {
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final isAuthenticated = authStateNotifier.value;
      final location = state.uri.toString();
      final isGoingToAuth = location.startsWith('/auth') ||
          location.startsWith('/onboarding') ||
          location.startsWith('/shop-setup') ||
          location.startsWith('/pin-lock') ||
          location.startsWith('/users');

      if (!isAuthenticated && !isGoingToAuth) return '/auth';
      if (isAuthenticated && location == '/auth') return '/';
      return null;
    },
    routes: [
      // Auth & Setup
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(path: '/shop-setup', builder: (context, state) => const CustomerShopSetupPage()),
      GoRoute(path: '/pin-lock', builder: (context, state) => const PinLockScreen(onUnlocked: null)),

       // Main Bottom Navigation Shell
       ShellRoute(
         builder: (context, state, child) => MainNavigationShell(child: child),
         routes: [
           GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
           GoRoute(path: '/new-sale', builder: (context, state) => const NewSalePage()),
           GoRoute(path: '/finance', builder: (context, state) => const HomePage()),
            GoRoute(path: '/reports', builder: (context, state) => const ReportsPage()),
            GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
          ],
        ),
       GoRoute(path: '/shop', builder: (context, state) => const ShopDetailsPage()),
       GoRoute(path: '/add-transaction', builder: (context, state) => const AddTransactionPage()),
       GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
       GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
       GoRoute(path: '/pin-lock', builder: (context, state) => const PinLockScreen()),
      GoRoute(path: '/invoice/:id', builder: (context, state) => InvoiceDetailPage(invoiceId: state.pathParameters['id']!)),
      GoRoute(path: '/shift-report', builder: (context, state) => ShiftReportPage(shiftId: state.uri.queryParameters['id'] ?? 'default')),
      GoRoute(path: '/shop-setup', builder: (context, state) => const CustomerShopSetupPage()),

// Standalone pages
        GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
        GoRoute(path: '/operations', builder: (context, state) => const OperationsPage()),
        GoRoute(path: '/planner', builder: (context, state) => const PlannerPage()),
        GoRoute(path: '/about', builder: (context, state) => const AboutAppPage()),
        GoRoute(path: '/terms', builder: (context, state) => const TermsConditionsPage()),
        GoRoute(path: '/privacy', builder: (context, state) => const PrivacyPolicyPage()),
        GoRoute(path: '/help-support', builder: (context, state) => const HelpSupportPage()),
 
       // Budgets
      GoRoute(path: '/budgets', builder: (context, state) => const BudgetListPage(), routes: [
        GoRoute(path: 'add', builder: (context, state) => const EditBudgetPage()),
        GoRoute(path: 'edit/:id', builder: (context, state) {
          final budget = state.extra as Budget?;
          return EditBudgetPage(budget: budget);
        }),
      ]),

      // Products
      GoRoute(path: '/products', builder: (context, state) => const ProductListPage(), routes: [
        GoRoute(path: 'add', builder: (context, state) => const AddProductPage()),
        GoRoute(path: 'edit/:id', builder: (context, state) {
          final product = state.extra as Product?;
          return EditProductPage(product: product ?? Product.empty());
        }),
      ]),

      // Customers
      GoRoute(path: '/customers', builder: (context, state) => const CustomerListPage(), routes: [
        GoRoute(path: 'add', builder: (context, state) => const AddCustomerPage()),
        GoRoute(path: 'edit/:id', builder: (context, state) {
          final customer = state.extra as Customer?;
          return EditCustomerPage(customer: customer ?? Customer.empty());
        }),
        GoRoute(path: 'transactions/:id', builder: (context, state) {
          final customerId = state.pathParameters['id']!;
          return CustomerTransactionsPage(customerId: customerId);
        }),
      ]),

      // Users
      GoRoute(path: '/users', builder: (context, state) => const UserListPage(), routes: [
        GoRoute(path: 'add', builder: (context, state) => const AddUserPage()),
        GoRoute(path: 'edit/:id', builder: (context, state) {
          final user = state.extra as User?;
          return EditUserPage(user: user ?? User.empty());
        }),
      ]),

      // Catch-all
      GoRoute(
        path: '/:path',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Page not found')),
        ),
      ),
    ],
  );
}
