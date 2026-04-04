import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes and provides access to the Supabase client.
///
/// Call [SupabaseService.initialize] once in [main] before using the client.
class SupabaseService {
  SupabaseService._();

  /// Supabase project URL. Replace with your project URL or load from env.
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );

  /// Supabase anon key. Replace with your anon key or load from env.
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  /// Initialize Supabase. Must be called before [client] is accessed.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Returns the initialized Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
