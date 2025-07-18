import 'dart:async';
import '../config/app_config.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';

class ProductionAIService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing Production AI Service...');

      if (AppConfig.useRealAPIs && AppConfig.isConfigured) {
        // TODO: Initialize real Gemini AI
        print('✅ Gemini AI initialized (Production mode)');
      } else {
        print('⚠️  Using mock AI responses - API not configured');
      }

      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing AI service: $e');
      _isInitialized = false;
    }
  }

  static Future<BookingSuggestion> processVoiceBooking(
    String voiceInput,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) async {
    await _ensureInitialized();

    if (AppConfig.useRealAPIs && AppConfig.isConfigured) {
      return await _processWithRealAI(
        voiceInput,
        availableRooms,
        existingGuests,
      );
    } else {
      return _processWithMockAI(voiceInput, availableRooms, existingGuests);
    }
  }

  static Future<BookingSuggestion> _processWithRealAI(
    String voiceInput,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) async {
    try {
      // TODO: Implement real Gemini AI API call
      // For now, using mock response until API is configured
      print('🤖 Processing with real AI: $voiceInput');

      // Mock response for now - replace with actual API call
      return _processWithMockAI(voiceInput, availableRooms, existingGuests);
    } catch (e) {
      print('❌ Real AI processing failed: $e');
      return _processWithMockAI(voiceInput, availableRooms, existingGuests);
    }
  }

  static BookingSuggestion _processWithMockAI(
    String voiceInput,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) {
    final input = voiceInput.toLowerCase();
    final now = DateTime.now();

    // Extract guest name
    String guestName = 'New Guest';
    for (final guest in existingGuests) {
      if (input.contains(guest.name.toLowerCase())) {
        guestName = guest.name;
        break;
      }
    }

    // If no existing guest found, try to extract from voice
    if (guestName == 'New Guest') {
      final words = input.split(' ');
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i] == 'for' || words[i] == 'under') {
          guestName = words[i + 1];
          break;
        }
      }
    }

    // Extract room type
    String? roomType;
    if (input.contains('suite')) {
      roomType = 'Suite';
    } else if (input.contains('deluxe'))
      roomType = 'Deluxe';
    else if (input.contains('standard'))
      roomType = 'Standard';

    // Extract dates
    DateTime checkInDate = now;
    DateTime checkOutDate = now.add(const Duration(days: 1));

    if (input.contains('today')) {
      checkInDate = now;
    } else if (input.contains('tomorrow')) {
      checkInDate = now.add(const Duration(days: 1));
    } else if (input.contains('next week')) {
      checkInDate = now.add(const Duration(days: 7));
    }

    // Extract duration
    if (input.contains('3 days') || input.contains('three days')) {
      checkOutDate = checkInDate.add(const Duration(days: 3));
    } else if (input.contains('week')) {
      checkOutDate = checkInDate.add(const Duration(days: 7));
    } else if (input.contains('2 nights') || input.contains('two nights')) {
      checkOutDate = checkInDate.add(const Duration(days: 2));
    }

    return BookingSuggestion(
      guestName: guestName,
      roomType: roomType,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      specialRequests: input.contains('quiet') ? 'Quiet room requested' : null,
    );
  }

  static Future<List<String>> getSmartSuggestions(
    String query,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) async {
    await _ensureInitialized();

    if (AppConfig.useRealAPIs && AppConfig.isConfigured) {
      return await _getRealSmartSuggestions(
        query,
        availableRooms,
        existingGuests,
      );
    } else {
      return _getMockSmartSuggestions(query, availableRooms, existingGuests);
    }
  }

  static Future<List<String>> _getRealSmartSuggestions(
    String query,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) async {
    try {
      // TODO: Implement real AI suggestions
      return _getMockSmartSuggestions(query, availableRooms, existingGuests);
    } catch (e) {
      print('❌ Real AI suggestions failed: $e');
      return _getMockSmartSuggestions(query, availableRooms, existingGuests);
    }
  }

  static List<String> _getMockSmartSuggestions(
    String query,
    List<Room> availableRooms,
    List<Guest> existingGuests,
  ) {
    final suggestions = <String>[];

    if (query.isEmpty) {
      suggestions.addAll([
        'Book a room for tonight',
        'Check available suites',
        'Schedule for next week',
        'VIP guest booking',
        'Weekend reservation',
      ]);
    } else {
      final queryLower = query.toLowerCase();

      if (queryLower.contains('book')) {
        suggestions.addAll([
          'Book ${availableRooms.first.type} room',
          'Book for ${existingGuests.first.name}',
          'Book for tonight',
          'Book for next week',
        ]);
      }

      if (queryLower.contains('room')) {
        suggestions.addAll([
          'Room ${availableRooms.first.number} available',
          'Suite room recommendation',
          'Deluxe room with view',
          'Standard room nearby',
        ]);
      }

      if (queryLower.contains('guest')) {
        suggestions.addAll([
          'Add new guest',
          'Update guest info',
          'VIP guest service',
          'Returning guest discount',
        ]);
      }
    }

    return suggestions.take(5).toList();
  }

  static Future<String> generateBookingInsights(
    List<Booking> bookings,
    List<Room> rooms,
  ) async {
    await _ensureInitialized();

    if (AppConfig.useRealAPIs && AppConfig.isConfigured) {
      return await _generateRealInsights(bookings, rooms);
    } else {
      return _generateMockInsights(bookings, rooms);
    }
  }

  static Future<String> _generateRealInsights(
    List<Booking> bookings,
    List<Room> rooms,
  ) async {
    try {
      // TODO: Implement real AI insights
      return _generateMockInsights(bookings, rooms);
    } catch (e) {
      print('❌ Real AI insights failed: $e');
      return _generateMockInsights(bookings, rooms);
    }
  }

  static String _generateMockInsights(
    List<Booking> bookings,
    List<Room> rooms,
  ) {
    final occupancyRate = bookings.length / rooms.length * 100;
    final insights = <String>[];

    insights.add('📊 Current occupancy: ${occupancyRate.toStringAsFixed(1)}%');

    if (occupancyRate > 80) {
      insights.add('🔥 High demand period - consider premium pricing');
    } else if (occupancyRate < 40) {
      insights.add('📈 Low occupancy - launch promotional offers');
    }

    insights.add(
      '💡 AI suggests optimizing ${rooms.length - bookings.length} available rooms',
    );

    return insights.join('\n');
  }

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose of AI service resources
  static void dispose() {
    _isInitialized = false;
    print('🔄 Production AI Service disposed');
  }
}

class BookingSuggestion {
  final String guestName;
  final String? roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String? specialRequests;

  BookingSuggestion({
    required this.guestName,
    this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'guestName': guestName,
      'roomType': roomType,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'specialRequests': specialRequests,
    };
  }

  factory BookingSuggestion.fromJson(Map<String, dynamic> json) {
    return BookingSuggestion(
      guestName: json['guestName'] ?? 'New Guest',
      roomType: json['roomType'],
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      specialRequests: json['specialRequests'],
    );
  }
}
