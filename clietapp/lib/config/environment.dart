class EnvironmentConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://wbuprrkpsxsyzjcvjmxl.supabase.co';

  // TODO: Replace with your actual Supabase anon key from Supabase Dashboard
  // Go to: https://supabase.com/dashboard -> Your Project -> Settings -> API
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_KEY',
    // Temporary demo key - REPLACE with your real anon key for production
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndidXBycmtwc3hzeXpqY3ZqbXhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY2MTQwMzEsImV4cCI6MjA1MjE5MDAzMX0.demo_key_replace_with_real',
  );

  // App Configuration
  static const String appName = 'Resort Booking Tracker';
  static const String appVersion = '1.0.0';

  // Development flags
  static const bool isDebugMode = true;
  static const bool enableLogging = true;

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Validation
  static bool get isSupabaseConfigured {
    return supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
        supabaseAnonKey != 'demo_key_replace_with_real' &&
        supabaseAnonKey.isNotEmpty &&
        supabaseUrl.isNotEmpty;
  }

  // Helper method to get configuration status
  static Map<String, dynamic> getConfigStatus() {
    return {
      'supabase_configured': isSupabaseConfigured,
      'url_set': supabaseUrl.isNotEmpty,
      'key_set':
          supabaseAnonKey.isNotEmpty &&
          supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
          supabaseAnonKey != 'demo_key_replace_with_real',
      'debug_mode': isDebugMode,
    };
  }
}
