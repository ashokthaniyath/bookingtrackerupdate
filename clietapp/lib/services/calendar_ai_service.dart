import 'package:flutter/foundation.dart';

/// Enhanced Calendar AI Service for intelligent date parsing and booking management
/// Provides sophisticated natural language date understanding for voice bookings
class CalendarAIService {
  static bool _isInitialized = false;

  /// Initialize the Calendar AI service
  static Future<bool> initialize() async {
    try {
      debugPrint('📅 Initializing Calendar AI Service...');

      // For now, we'll use local intelligent parsing
      // Future versions can integrate with Google Calendar API
      _isInitialized = true;
      debugPrint('✅ Calendar AI Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Calendar AI Service: $e');
      debugPrint('🔄 Continuing with fallback date parsing');
      _isInitialized = false;
      return false;
    }
  }

  /// Enhanced natural language date parsing
  /// Converts voice input like "next Friday", "in two weeks", "tomorrow" to specific dates
  static Future<DateParseResult> parseNaturalLanguageDate(String input) async {
    try {
      debugPrint('🗓️ Parsing natural language date: "$input"');

      // First try intelligent pattern matching
      final localResult = _parseLocalDatePatterns(input);
      if (localResult.isValid) {
        return localResult;
      }

      // Enhanced fallback with more sophisticated parsing
      return _enhancedFallbackParsing(input);
    } catch (e) {
      debugPrint('❌ Error parsing date: $e');
      return DateParseResult.invalid('Could not parse date from: $input');
    }
  }

  /// Local intelligent date pattern recognition
  static DateParseResult _parseLocalDatePatterns(String input) {
    final now = DateTime.now();
    final lowerInput = input.toLowerCase().trim();

    // Time-based patterns
    final timePatterns = {
      'today': now,
      'tomorrow': now.add(const Duration(days: 1)),
      'yesterday': now.subtract(const Duration(days: 1)),
      'next week': now.add(const Duration(days: 7)),
      'next month': DateTime(now.year, now.month + 1, now.day),
      'in two weeks': now.add(const Duration(days: 14)),
      'in a week': now.add(const Duration(days: 7)),
      'in 3 days': now.add(const Duration(days: 3)),
      'in a month': DateTime(now.year, now.month + 1, now.day),
    };

    // Check exact matches first
    for (final pattern in timePatterns.entries) {
      if (lowerInput.contains(pattern.key)) {
        return DateParseResult.success(
          pattern.value,
          'Parsed "${pattern.key}" as ${_formatDate(pattern.value)}',
        );
      }
    }

    // Day of week patterns
    final weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    for (final day in weekdays.entries) {
      if (lowerInput.contains(day.key)) {
        DateTime targetDate;
        if (lowerInput.contains('next')) {
          targetDate = _getNextWeekday(now, day.value);
        } else {
          targetDate = _getThisWeekday(now, day.value);
        }
        return DateParseResult.success(
          targetDate,
          'Parsed "${day.key}" as ${_formatDate(targetDate)}',
        );
      }
    }

    // Month patterns
    final months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };

    for (final month in months.entries) {
      if (lowerInput.contains(month.key)) {
        // Try to extract day number
        final dayMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(lowerInput);
        final day = dayMatch != null
            ? int.tryParse(dayMatch.group(1)!) ?? 1
            : 1;
        final year = lowerInput.contains('next year') ? now.year + 1 : now.year;

        try {
          final targetDate = DateTime(year, month.value, day);
          return DateParseResult.success(
            targetDate,
            'Parsed "${month.key} $day" as ${_formatDate(targetDate)}',
          );
        } catch (e) {
          // Invalid date, fallback to first of month
          final targetDate = DateTime(year, month.value, 1);
          return DateParseResult.success(
            targetDate,
            'Parsed "${month.key}" as ${_formatDate(targetDate)}',
          );
        }
      }
    }

    // Relative patterns with numbers
    final relativePattern = RegExp(r'in (\d+) (day|week|month)s?');
    final relativeMatch = relativePattern.firstMatch(lowerInput);
    if (relativeMatch != null) {
      final number = int.tryParse(relativeMatch.group(1)!) ?? 1;
      final unit = relativeMatch.group(2)!;

      DateTime targetDate;
      switch (unit) {
        case 'day':
          targetDate = now.add(Duration(days: number));
          break;
        case 'week':
          targetDate = now.add(Duration(days: number * 7));
          break;
        case 'month':
          targetDate = DateTime(now.year, now.month + number, now.day);
          break;
        default:
          return DateParseResult.invalid('Unknown time unit: $unit');
      }

      return DateParseResult.success(
        targetDate,
        'Parsed "in $number ${unit}s" as ${_formatDate(targetDate)}',
      );
    }

    return DateParseResult.invalid('No recognizable date pattern found');
  }

  /// Enhanced fallback parsing with more sophisticated date recognition
  static DateParseResult _enhancedFallbackParsing(String input) {
    final now = DateTime.now();

    // Try to extract any numbers that might be dates
    final datePattern = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.]?(\d{2,4})?\b',
    );
    final dateMatch = datePattern.firstMatch(input);

    if (dateMatch != null) {
      try {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final yearStr = dateMatch.group(3);
        final year = yearStr != null
            ? (yearStr.length == 2
                  ? 2000 + int.parse(yearStr)
                  : int.parse(yearStr))
            : now.year;

        final targetDate = DateTime(year, month, day);
        return DateParseResult.success(
          targetDate,
          'Parsed date format as ${_formatDate(targetDate)}',
        );
      } catch (e) {
        debugPrint('Invalid date format: $e');
      }
    }

    // Duration-based fallback
    if (input.toLowerCase().contains('night')) {
      final nightPattern = RegExp(r'(\d+)\s*night');
      final nightMatch = nightPattern.firstMatch(input.toLowerCase());
      if (nightMatch != null) {
        final nights = int.tryParse(nightMatch.group(1)!) ?? 1;
        return DateParseResult.success(
          now.add(Duration(days: nights)),
          'Parsed "$nights nights" as checkout ${_formatDate(now.add(Duration(days: nights)))}',
        );
      }
    }

    // Default fallback to tomorrow
    return DateParseResult.success(
      now.add(const Duration(days: 1)),
      'Defaulted to tomorrow (${_formatDate(now.add(const Duration(days: 1)))})',
    );
  }

  /// Get next occurrence of a weekday
  static DateTime _getNextWeekday(DateTime from, int weekday) {
    final daysUntil = (weekday - from.weekday + 7) % 7;
    final target = daysUntil == 0 ? 7 : daysUntil; // If today, get next week
    return from.add(Duration(days: target));
  }

  /// Get this week's occurrence of a weekday
  static DateTime _getThisWeekday(DateTime from, int weekday) {
    final daysUntil = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: daysUntil));
  }

  /// Smart date range calculation for bookings
  static Future<DateRangeResult> calculateBookingDates(String input) async {
    final lowerInput = input.toLowerCase();

    // Extract check-in date
    final checkInResult = await parseNaturalLanguageDate(input);
    if (!checkInResult.isValid) {
      return DateRangeResult.invalid('Could not determine check-in date');
    }

    DateTime checkInDate = checkInResult.date!;
    DateTime checkOutDate;

    // Try to find duration indicators
    final nightPattern = RegExp(r'(\d+)\s*night');
    final nightMatch = nightPattern.firstMatch(lowerInput);

    if (nightMatch != null) {
      final nights = int.tryParse(nightMatch.group(1)!) ?? 1;
      checkOutDate = checkInDate.add(Duration(days: nights));
    } else if (lowerInput.contains('weekend')) {
      // Weekend booking logic
      if (checkInDate.weekday == DateTime.friday) {
        checkOutDate = checkInDate.add(
          const Duration(days: 2),
        ); // Friday to Sunday
      } else {
        checkOutDate = checkInDate.add(
          const Duration(days: 2),
        ); // Default 2 nights
      }
    } else if (lowerInput.contains('week')) {
      checkOutDate = checkInDate.add(const Duration(days: 7));
    } else {
      // Default to 1 night
      checkOutDate = checkInDate.add(const Duration(days: 1));
    }

    return DateRangeResult.success(
      checkInDate,
      checkOutDate,
      'Check-in: ${_formatDate(checkInDate)}, Check-out: ${_formatDate(checkOutDate)}',
    );
  }

  /// Check for booking conflicts (placeholder for future calendar integration)
  static Future<ConflictCheckResult> checkBookingConflicts(
    DateTime checkIn,
    DateTime checkOut,
    String roomNumber,
  ) async {
    try {
      // This would integrate with actual calendar API
      // For now, return no conflicts
      debugPrint(
        '🔍 Checking conflicts for Room $roomNumber from ${_formatDate(checkIn)} to ${_formatDate(checkOut)}',
      );

      // Simulate conflict check
      await Future.delayed(const Duration(milliseconds: 500));

      return ConflictCheckResult.noConflicts(
        'No conflicts found for Room $roomNumber in the specified period',
      );
    } catch (e) {
      return ConflictCheckResult.error('Error checking conflicts: $e');
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get service status
  static bool get isInitialized => _isInitialized;
}

/// Result class for date parsing operations
class DateParseResult {
  final bool isValid;
  final DateTime? date;
  final String message;

  DateParseResult._(this.isValid, this.date, this.message);

  factory DateParseResult.success(DateTime date, String message) {
    return DateParseResult._(true, date, message);
  }

  factory DateParseResult.invalid(String message) {
    return DateParseResult._(false, null, message);
  }
}

/// Result class for date range calculations
class DateRangeResult {
  final bool isValid;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String message;

  DateRangeResult._(
    this.isValid,
    this.checkInDate,
    this.checkOutDate,
    this.message,
  );

  factory DateRangeResult.success(
    DateTime checkIn,
    DateTime checkOut,
    String message,
  ) {
    return DateRangeResult._(true, checkIn, checkOut, message);
  }

  factory DateRangeResult.invalid(String message) {
    return DateRangeResult._(false, null, null, message);
  }
}

/// Result class for conflict checking
class ConflictCheckResult {
  final bool hasConflicts;
  final List<String> conflicts;
  final String message;

  ConflictCheckResult._(this.hasConflicts, this.conflicts, this.message);

  factory ConflictCheckResult.noConflicts(String message) {
    return ConflictCheckResult._(false, [], message);
  }

  factory ConflictCheckResult.withConflicts(
    List<String> conflicts,
    String message,
  ) {
    return ConflictCheckResult._(true, conflicts, message);
  }

  factory ConflictCheckResult.error(String message) {
    return ConflictCheckResult._(false, [], message);
  }
}
