import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, User;
import '../../../../core/supabase/supabase_config.dart';
import 'auth_state.dart';
import '../../../auth/domain/entities/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;

  AuthBloc(this._supabase) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthGetUsersRequested>(_onAuthGetUsersRequested);

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        add(const AuthCheckRequested());
      } else {
        add(const AuthLogoutRequested());
      }
    });
  }

    void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser != null) {
      // Convert Supabase User to our User entity
      final appUser = User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? '',
        name: supabaseUser.userMetadata != null && supabaseUser.userMetadata!['full_name'] != null
            ? supabaseUser.userMetadata!['full_name'] as String
            : supabaseUser.email?.split('@')[0] ?? 'Unknown User',
        phone: supabaseUser.phone,
        role: UserRole.cashier,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      emit(AuthAuthenticated(appUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // Check if Supabase is properly configured
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthError('Supabase is not properly configured. Please check your project credentials in supabase_config.dart'));
      return;
    }

    try {
      await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      // Auth state change will be handled by the listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthSignupRequested(AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // Check if Supabase is properly configured
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthError('Supabase is not properly configured. Please check your project credentials in supabase_config.dart'));
      return;
    }

    try {
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'shop_name': event.shopName,
          'phone_number': event.phoneNumber,
        },
      );

      // If signup was successful and we have a user, sign them in automatically
      if (response.user != null) {
        // Automatically sign in the user to create a session
        await _supabase.auth.signInWithPassword(
          email: event.email,
          password: event.password,
        );
        // Auth state change will be handled by the listener
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _supabase.auth.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

    Future<void> _onAuthPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
     try {
       await _supabase.auth.resetPasswordForEmail(event.email);
     } catch (e) {
       emit(AuthError(e.toString()));
     }
   }

    void _onAuthGetUsersRequested(AuthGetUsersRequested event, Emitter<AuthState> emit) async {
      emit(const AuthLoading());
      try {
        // For now, we'll return mock data since Supabase doesn't have a direct users table query
        // In a real implementation, you would query your users table or use Supabase admin features
        final users = [
          User(
            id: '1',
            email: 'admin@twigapos.com',
            name: 'Administrator',
            phone: '+255 123 456 789',
            role: UserRole.admin,
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now(),
            lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          User(
            id: '2',
            email: 'manager@twigapos.com',
            name: 'Store Manager',
            phone: '+255 987 654 321',
            role: UserRole.manager,
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            updatedAt: DateTime.now(),
            lastLoginAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          User(
            id: '3',
            email: 'cashier@twigapos.com',
            name: 'Cashier One',
            role: UserRole.cashier,
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now(),
            lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];
        emit(AuthUsersLoaded(users));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    }
 }
