/// Voice AI Configuration for Speech-to-Text and Text-to-Speech
class VoiceAIConfig {
  // Unified Google API Key - Updated July 16, 2025
  static const String speechToTextApiKey =
      'AIzaSyAC6_qZ1iZRXixY77sjHZdnxApD3pLlxcY';

  // Speech-to-Text Configuration
  static const String speechApiEndpoint =
      'https://speech.googleapis.com/v1/speech:recognize';

  // Voice Recognition Settings
  static const String languageCode = 'en-US';
  static const int sampleRateHertz = 16000;
  static const Duration maxRecordingTime = Duration(seconds: 30);
  static const Duration listeningTimeout = Duration(seconds: 10);

  // Text-to-Speech Settings
  static const double speechRate = 0.5;
  static const double volume = 1.0;
  static const double pitch = 1.0;
  static const String ttsLanguage = 'en-US';

  // Voice Commands
  static const List<String> wakeWords = [
    'hey assistant',
    'booking assistant',
    'voice booking',
    'start booking',
  ];

  static const List<String> confirmationWords = [
    'yes',
    'confirm',
    'okay',
    'sure',
    'proceed',
    'book it',
  ];

  static const List<String> cancellationWords = [
    'no',
    'cancel',
    'stop',
    'abort',
    'nevermind',
  ];

  // API Headers
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': speechToTextApiKey,
  };

  // Voice Response Templates
  static const Map<String, String> voiceResponses = {
    'welcome': 'Welcome to the booking assistant. How can I help you today?',
    'listening': 'I\'m listening. Please speak your booking request.',
    'processing': 'Processing your request. Please wait.',
    'error': 'Sorry, I didn\'t understand that. Could you please repeat?',
    'confirmation': 'I\'ve found a booking option. Should I proceed?',
    'success': 'Booking completed successfully!',
    'cancelled': 'Booking cancelled. Is there anything else I can help with?',
    'help':
        'You can say things like: Book a room for John Smith tomorrow, or Reserve a deluxe room for 3 nights.',
  };
}
