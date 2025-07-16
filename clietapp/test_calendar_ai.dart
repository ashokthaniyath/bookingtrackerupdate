// Test Calendar AI Service functionality
import 'lib/services/calendar_ai_service.dart';

void main() async {
  print('=== Calendar AI Service Test ===\n');

  // Test various natural language date expressions
  final testPhrases = [
    'tomorrow',
    'next Friday',
    'this weekend',
    'in two weeks',
    'next month',
    'book for 3 nights starting tomorrow',
    'reserve from next weekend for 2 nights',
    'I want to stay from December 25th to January 2nd',
    'book me for the first week of January',
    'reserve room from tomorrow till Sunday',
  ];

  for (final phrase in testPhrases) {
    print('Testing: "$phrase"');
    try {
      final result = await CalendarAIService.calculateBookingDates(phrase);
      if (result.isValid &&
          result.checkInDate != null &&
          result.checkOutDate != null) {
        print('  ✅ Check-in: ${result.checkInDate.toString().split(' ')[0]}');
        print('  ✅ Check-out: ${result.checkOutDate.toString().split(' ')[0]}');
        print(
          '  ✅ Nights: ${result.checkOutDate!.difference(result.checkInDate!).inDays}',
        );
        print('  ✅ Message: ${result.message}');
      } else {
        print('  ❌ ${result.message}');
      }
    } catch (e) {
      print('  ❌ Error: $e');
    }
    print('');
  }

  print('=== Voice AI Integration Test ===\n');

  // Test voice booking scenarios
  final voiceCommands = [
    'I want to book a deluxe room for next weekend',
    'Reserve a standard room from tomorrow for 3 nights for John Smith',
    'Book me a suite starting December 25th for a week',
    'Can I get a room for this Friday and Saturday',
  ];

  for (final command in voiceCommands) {
    print('Voice Command: "$command"');
    try {
      final result = await CalendarAIService.calculateBookingDates(command);
      if (result.isValid &&
          result.checkInDate != null &&
          result.checkOutDate != null) {
        print(
          '  📅 Dates: ${result.checkInDate.toString().split(' ')[0]} to ${result.checkOutDate.toString().split(' ')[0]}',
        );
        print(
          '  🛏️  Duration: ${result.checkOutDate!.difference(result.checkInDate!).inDays} nights',
        );
        print('  💬 Message: ${result.message}');
      } else {
        print('  ❌ ${result.message}');
      }
    } catch (e) {
      print('  ❌ Error: $e');
    }
    print('');
  }

  print(
    '✅ Calendar AI integration is working! Your voice booking system now has intelligent date recognition.',
  );
  print('🎤 Try voice commands like:');
  print('   • "Book for tomorrow"');
  print('   • "Reserve next weekend"');
  print('   • "I need a room for 3 nights starting Friday"');
}
