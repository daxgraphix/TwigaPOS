import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase project credentials
  // Get these from your Supabase project dashboard at https://supabase.com/dashboard
  // Replace these with your actual Supabase project credentials
  // Get them from: https://supabase.com/dashboard → Settings → API
  // Your Supabase project credentials
  static const String supabaseUrl = 'https://dwmdldxsvmpexskkgopr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3bWRsZHhzdm1wZXhza2tnb3ByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NTk4ODgsImV4cCI6MjA5NDIzNTg4OH0.xX_1IFaNfoFOLN7gtEcv82QmaAQ40ccf2BKCJTodBVk';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Helper method to check if Supabase is properly configured
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL_HERE' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.length > 50; // Basic validation

  // Debug method to test Supabase connection
  static Future<bool> testConnection() async {
    try {
      // Try to get the current user (this will test if the client is working)
      await client.auth.getUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Basic sync helper for multi-device (call from repositories on data change)
  static Future<void> syncData(String table, Map<String, dynamic> data) async {
    try {
      await client.from(table).upsert(data);
    } catch (_) {}
  }

  // Profile image upload helper
  static Future<String?> uploadProfileImage(String userId, File image) async {
    try {
      final path = 'profiles/$userId.jpg';
      await client.storage.from('avatars').upload(path, image);
      return client.storage.from('avatars').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }
}