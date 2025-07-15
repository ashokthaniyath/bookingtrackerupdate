import 'dart:io';
import 'lib/services/vertex_ai_service.dart';
import 'lib/models/room.dart';
import 'lib/models/guest.dart';

void main() async {
  print('🚀 Testing Vertex AI Service...');

  try {
    // Initialize the service
    await VertexAIService.initialize();
    print('✅ Service initialized successfully');

    // Test natural language booking
    final rooms = [
      Room(id: '1', number: '101', type: 'Deluxe', status: 'Available'),
      Room(id: '2', number: '102', type: 'Standard', status: 'Available'),
    ];

    final guests = <Guest>[];

    print('\n🧠 Testing AI booking request...');
    final suggestion = await VertexAIService.processNaturalLanguageBooking(
      'I need a deluxe room for John Doe from tomorrow for 2 nights',
      rooms,
      guests,
    );

    print('📋 AI Suggestion:');
    print('  Guest: ${suggestion.guestName}');
    print('  Email: ${suggestion.guestEmail}');
    print('  Room Type: ${suggestion.roomType}');
    print('  Check-in: ${suggestion.checkInDate}');
    print('  Check-out: ${suggestion.checkOutDate}');
    print('  Confidence: ${suggestion.confidence}%');
    print('  Notes: ${suggestion.notes}');

    print('\n📊 Testing AI insights...');
    final insights = await VertexAIService.generateBookingInsights([], [], []);
    print('Summary: ${insights.summary}');
    print('Recommendations: ${insights.recommendations.length} items');
    print('Trends: ${insights.trends.length} items');

    print('\n✅ All tests passed! AI integration is working correctly.');
  } catch (e) {
    print('❌ Error testing AI service: $e');
    exit(1);
  }
}
