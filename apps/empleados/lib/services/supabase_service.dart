import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes and provides access to the Supabase client.
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
