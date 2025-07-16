/// Vertex AI Configuration
/// Configuration settings for Google Cloud Vertex AI integration
class VertexAIConfig {
  // UNIFIED API KEY - All Google Cloud Services
  // Updated: July 16, 2025 - Using user's unified key for all services
  static const String unifiedApiKey = 'AIzaSyAC6_qZ1iZRXixY77sjHZdnxApD3pLlxcY';

  // Backward compatibility - all services use the unified key
  static const String generativeLanguageApiKey = unifiedApiKey;
  static const String speechToTextApiKey = unifiedApiKey;
  static const String calendarApiKey = unifiedApiKey;
  static const String firebaseBrowserKey = unifiedApiKey;
  static const String firebaseIosKey = unifiedApiKey;
  static const String firebaseAndroidKey = unifiedApiKey;

  // Google Cloud Project Configuration
  static const String projectId = 'project-1-c7622'; // Your Firebase project ID
  static const String region = 'us-central1'; // Or your preferred region

  // API Endpoints - Using Generative Language API
  static const String baseUrl = 'https://generativelanguage.googleapis.com';
  static const String apiVersion = 'v1beta';

  // Model Configuration
  static const String defaultModel = 'gemini-1.5-flash'; // Using Gemini model
  static const String chatModel = 'gemini-1.5-flash';
  static const String embeddingModel = 'text-embedding-004';

  // Request Parameters
  static const int maxTokens = 1024;
  static const double temperature = 0.3;
  static const double topP = 0.95;
  static const int topK = 40;

  // Authentication
  static const String serviceAccountKeyPath =
      'path/to/service-account-key.json';

  // Feature Flags
  static const bool enableLogging = true;
  static const bool enableMockResponses = false; // Now using real API
  static const bool enableErrorRetry = true;
  static const int maxRetryAttempts = 3;

  // Rate Limiting
  static const int requestsPerMinute = 60;
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Get the full API endpoint for text generation
  static String getTextGenerationEndpoint() {
    return '$baseUrl/$apiVersion/models/$defaultModel:generateContent?key=$generativeLanguageApiKey';
  }

  /// Get the full API endpoint for chat
  static String getChatEndpoint() {
    return '$baseUrl/$apiVersion/models/$chatModel:generateContent?key=$generativeLanguageApiKey';
  }

  /// Get authentication headers for API key authentication
  static Map<String, String> getAuthHeaders() {
    return {'Content-Type': 'application/json'};
  }
}

/// Environment-specific configurations
class VertexAIEnvironment {
  static const Map<String, VertexAIEnvConfig> environments = {
    'development': VertexAIEnvConfig(
      projectId: 'project-1-c7622',
      enableMockResponses: false,
      enableLogging: true,
    ),
    'staging': VertexAIEnvConfig(
      projectId: 'project-1-c7622',
      enableMockResponses: false,
      enableLogging: true,
    ),
    'production': VertexAIEnvConfig(
      projectId: 'project-1-c7622',
      enableMockResponses: false,
      enableLogging: false,
    ),
  };

  static VertexAIEnvConfig get current {
    const environment = String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: 'development',
    );
    return environments[environment] ?? environments['development']!;
  }
}

/// Environment-specific configuration
class VertexAIEnvConfig {
  final String projectId;
  final bool enableMockResponses;
  final bool enableLogging;

  const VertexAIEnvConfig({
    required this.projectId,
    required this.enableMockResponses,
    required this.enableLogging,
  });
}
