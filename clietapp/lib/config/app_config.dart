class AppConfig {
  // Production mode flags
  static const bool isProduction = true;
  static const bool useFirebase = true;
  static const bool useRealAPIs = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  // App information
  static const String appName = 'Booking Tracker Pro';
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  // Firebase configuration
  static const String firebaseProjectId = 'booking-tracker-prod';
  static const String firebaseApiKey = 'YOUR_API_KEY_HERE';
  static const String firebaseDomain = 'booking-tracker-prod.firebaseapp.com';

  // Google Cloud AI configuration
  static const String googleCloudProjectId = 'booking-tracker-prod';
  static const String vertexAILocation = 'us-central1';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Feature flags
  static const bool enableVoiceAI = true;
  static const bool enableSmartBooking = true;
  static const bool enableCalendarAI = true;
  static const bool enableRealTimeUpdates = true;
  static const bool enableOfflineMode = true;

  // Debug settings
  static const bool isDebugMode = false; // Set to false for production
  static const bool isReleaseMode = true;

  // API endpoints
  static const String baseUrl = 'https://api.booking-tracker.com';
  static const String websocketUrl = 'wss://ws.booking-tracker.com';

  // Cache settings
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 100; // MB

  // Network settings
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Security configuration
  static const bool enableEncryption = true;
  static const bool enableSecurityMonitoring = true;

  // Validation
  static bool get isConfigured =>
      firebaseApiKey != 'YOUR_API_KEY_HERE' &&
      geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
}
