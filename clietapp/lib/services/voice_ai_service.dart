import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/guest.dart';
import '../models/room.dart';
import 'vertex_ai_service.dart';

/// Mock Voice AI Service for testing without speech_to_text dependency
class VoiceAIService {
  static late FlutterTts _flutterTts;
  static bool _isInitialized = false;
  static bool _isListening = false;
  static bool _isSpeaking = false;
  static String _lastWords = '';

  // Stream controllers
  static final StreamController<String> _speechController =
      StreamController<String>.broadcast();
  static final StreamController<bool> _listeningController =
      StreamController<bool>.broadcast();
  static final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  // Getters
  static Stream<String> get speechStream => _speechController.stream;
  static Stream<bool> get listeningStream => _listeningController.stream;
  static Stream<bool> get speakingStream => _speakingController.stream;
  static bool get isListening => _isListening;
  static bool get isSpeaking => _isSpeaking;
  static String get lastWords => _lastWords;

  /// Initialize voice AI services (mock implementation)
  static Future<bool> initialize() async {
    try {
      debugPrint('🎤 Initializing Voice AI Service (Mock Mode)...');

      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _isInitialized = true;
      debugPrint('✅ Voice AI Service initialized (Mock Mode)');
      return true;
    } catch (e) {
      debugPrint('❌ Voice AI Service initialization failed: $e');
      return false;
    }
  }

  /// Start listening (mock implementation)
  static Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onError,
  }) async {
    if (!_isInitialized || _isListening || _isSpeaking) return;

    try {
      _isListening = true;
      _listeningController.add(true);
      debugPrint('🎤 Mock listening started...');

      await Future.delayed(const Duration(seconds: 2));

      final mockInputs = [
        "Book a room for John Smith",
        "Check availability this weekend",
        "Cancel booking for room 101",
        "Show me today's bookings",
      ];

      final randomInput =
          mockInputs[DateTime.now().millisecond % mockInputs.length];
      _lastWords = randomInput;

      _speechController.add(_lastWords);
      onResult?.call(_lastWords);

      await stopListening();
    } catch (e) {
      _isListening = false;
      _listeningController.add(false);
      onError?.call(e.toString());
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    _listeningController.add(false);
    debugPrint('🎤 Stopped listening');
  }

  /// Stop voice operations
  static Future<void> stop() async {
    await stopListening();
    await stopSpeaking();
  }

  /// Speak text using TTS
  static Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    try {
      debugPrint('🔊 Speaking: $text');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ Error speaking: $e');
    }
  }

  /// Stop speaking
  static Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController.add(false);
    } catch (e) {
      debugPrint('❌ Error stopping speech: $e');
    }
  }

  /// Process voice booking with Calendar AI (mock implementation)
  static Future<BookingSuggestion?> processVoiceBookingWithCalendarAI(
    String voiceInput,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) async {
    try {
      debugPrint('🤖 Processing voice booking (Mock): $voiceInput');

      await speak('Processing your booking request...');

      // Mock processing delay
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock booking suggestion
      final mockSuggestion = BookingSuggestion(
        guestName: 'John Smith',
        roomType: 'Standard Room',
        checkInDate: DateTime.now().add(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 3)),
        confidence: 0.85,
        notes: 'Mock booking suggestion from voice input: $voiceInput',
      );

      await speak(
        'I found a room for ${mockSuggestion.guestName}. Please review the details.',
      );

      return mockSuggestion;
    } catch (e) {
      debugPrint('❌ Error processing voice booking: $e');
      await speak('Sorry, I encountered an error processing your request.');
      return null;
    }
  }

  /// Confirm booking by voice (mock implementation)
  static Future<bool> confirmBookingByVoice() async {
    try {
      await speak("Please say 'yes' to confirm or 'no' to cancel.");

      // Mock confirmation - return true for testing
      await Future.delayed(const Duration(seconds: 2));
      await speak("Confirmed! Your booking has been created.");

      return true;
    } catch (e) {
      debugPrint('❌ Error in voice confirmation: $e');
      return false;
    }
  }

  /// Speak help information
  static Future<void> speakHelp() async {
    try {
      const helpText =
          "You can say things like: Book a room for John Smith, "
          "Check availability this weekend, or Cancel a booking. "
          "Tap the microphone to start speaking.";
      await speak(helpText);
    } catch (e) {
      debugPrint('❌ Error speaking help: $e');
    }
  }

  /// Test voice functionality
  static Future<void> testVoice() async {
    try {
      await speak(
        "Voice AI test successful. All systems are working properly.",
      );
    } catch (e) {
      debugPrint('❌ Error in voice test: $e');
    }
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    try {
      await stopListening();
      await stopSpeaking();
      await _speechController.close();
      await _listeningController.close();
      await _speakingController.close();
      _isInitialized = false;
      debugPrint('🧹 Voice AI Service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing Voice AI Service: $e');
    }
  }

  /// Check if voice features are available
  static bool get isAvailable => _isInitialized;

  /// Get status
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'listening': _isListening,
      'speaking': _isSpeaking,
      'lastWords': _lastWords,
      'mode': 'mock',
    };
  }
}
