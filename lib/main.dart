import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'config/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/service_locator.dart' as di;
import 'core/supabase/supabase_config.dart';
import 'core/data/hive_database.dart';
import 'l10n/app_localizations.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/billing/domain/repositories/sales_repository.dart';
import 'features/billing/domain/repositories/customer_repository.dart';
import 'features/product/domain/repositories/stock_repository.dart';
import 'features/finance/domain/repositories/transaction_repository.dart';
import 'features/finance/presentation/bloc/budget_cubit.dart';
import 'features/finance/presentation/bloc/account_cubit.dart';
import 'features/finance/presentation/bloc/report_cubit.dart';
import 'features/finance/presentation/bloc/transaction_bloc.dart';

class AuthStateNotifier extends ValueNotifier<bool> {
  AuthStateNotifier() : super(false);

  void updateState(AuthState state) {
    value = state is AuthAuthenticated;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for release builds
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // In release, you could log to a file here
  };

  String? initError;

  try {
    await HiveDatabase.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    initError = 'Database error: $e';
    debugPrint('Hive init failed: $e');
  }

  try {
    await di.init();
  } catch (e) {
    if (initError == null) initError = 'Service error: $e';
    debugPrint('DI init failed: $e');
  }

  try {
    await SupabaseConfig.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  try {
    final settingsBox = Hive.box('settings');
    final themeModeStr = settingsBox.get('themeMode', defaultValue: 'light');
    AppTheme.themeModeNotifier.value = themeModeStr == 'dark'
        ? ThemeMode.dark
        : themeModeStr == 'system'
            ? ThemeMode.system
            : ThemeMode.light;

    final langCode = settingsBox.get('languageCode', defaultValue: 'en');
    AppTheme.localeNotifier.value = Locale(langCode);

    if (settingsBox.get('isInitialized', defaultValue: false) == false) {
      await settingsBox.put('isInitialized', true);
    }
  } catch (e) {
    debugPrint('Settings restore failed: $e');
  }

  runApp(MyApp(initError: initError));
}

class MyApp extends StatefulWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthStateNotifier _authStateNotifier = AuthStateNotifier();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createRouter(_authStateNotifier);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!Hive.isBoxOpen('settings')) return;
      final pinEnabled = Hive.box('settings').get('pinEnabled', defaultValue: false);
      if (pinEnabled) {
        Hive.box('settings').put('pinVerified', false);
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != '/pin-lock') {
          context.push('/pin-lock');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start TwigaPOS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Simple restart by recreating the app
                      runApp(const MyApp());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SalesRepository>(
          create: (context) => di.sl<SalesRepository>(),
        ),
        RepositoryProvider<CustomerRepository>(
          create: (context) => di.sl<CustomerRepository>(),
        ),
        RepositoryProvider<StockRepository>(
          create: (context) => di.sl<StockRepository>(),
        ),
        RepositoryProvider<TransactionRepository>(
          create: (context) => di.sl<TransactionRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) {
              final authBloc = AuthBloc(SupabaseConfig.client)..add(const AuthCheckRequested());

              authBloc.stream.listen((state) {
                _authStateNotifier.updateState(state);
              });

              return authBloc;
            },
          ),
          BlocProvider<ProductBloc>(
              create: (context) => di.sl<ProductBloc>()),
          BlocProvider<ShopBloc>(
              create: (context) => di.sl<ShopBloc>()),
          BlocProvider<BillingBloc>(
              create: (context) => di.sl<BillingBloc>()),
          BlocProvider<FinanceBloc>(
            create: (context) => di.sl<FinanceBloc>()),
          BlocProvider<BudgetCubit>(
              create: (context) => di.sl<BudgetCubit>()),
          BlocProvider<AccountCubit>(
              create: (context) => di.sl<AccountCubit>()),
          BlocProvider<ReportCubit>(
              create: (context) => di.sl<ReportCubit>()),
          BlocProvider<TransactionBloc>(
              create: (context) => di.sl<TransactionBloc>()),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, themeMode, child) {
            return ValueListenableBuilder<Locale>(
              valueListenable: AppTheme.localeNotifier,
              builder: (context, locale, child) {
                return MaterialApp.router(
                  title: 'TwigaPOS',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en'), // English
                    Locale('sw'), // Swahili
                  ],
                  routerConfig: _router,
                  debugShowCheckedModeBanner: false,
                );
              },
            );
          },
        ),
      ),
    );
  }
}


