import 'package:flutter_test/flutter_test.dart';
import 'package:clietapp/services/vertex_ai_service.dart';
import 'package:clietapp/models/room.dart';
import 'package:clietapp/models/guest.dart';
import 'package:clietapp/models/booking.dart';
import 'package:clietapp/models/payment.dart';

void main() {
  group('VertexAIService Tests', () {
    setUpAll(() async {
      // Initialize the service
      await VertexAIService.initialize();
    });

    test('should initialize successfully', () {
      expect(VertexAIService, isNotNull);
    });

    test('should process natural language booking request', () async {
      // Arrange
      final input =
          "I need a deluxe room for Shajil Thaniyath from tomorrow for 2 nights";
      final availableRooms = [
        Room(id: '1', number: '101', type: 'Deluxe', status: 'Available'),
      ];
      final existingGuests = <Guest>[];

      // Act
      final result = await VertexAIService.processNaturalLanguageBooking(
        input,
        availableRooms,
        existingGuests,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.guestName, isNotEmpty);
      expect(result.confidence, greaterThan(0));
    });

    test('should generate booking insights', () async {
      // Arrange
      final bookings = <Booking>[];
      final payments = <Payment>[];
      final rooms = <Room>[];

      // Act
      final insights = await VertexAIService.generateBookingInsights(
        bookings,
        payments,
        rooms,
      );

      // Assert
      expect(insights, isNotNull);
      expect(insights.summary, isNotEmpty);
    });

    test('should suggest optimal pricing', () async {
      // Arrange
      final room = Room(
        id: '1',
        number: '101',
        type: 'Deluxe',
        status: 'Available',
      );
      final checkIn = DateTime.now().add(Duration(days: 1));
      final checkOut = DateTime.now().add(Duration(days: 3));
      final historicalBookings = <Booking>[];

      // Act
      final pricing = await VertexAIService.suggestOptimalPricing(
        room,
        checkIn,
        checkOut,
        historicalBookings,
      );

      // Assert
      expect(pricing, isNotNull);
      expect(pricing.suggestedPrice, greaterThan(0));
      expect(pricing.confidence, greaterThan(0));
    });

    test('should generate invoice description', () async {
      // Arrange
      final guest = Guest(
        name: 'Shajil Thaniyath',
        email: 'shajil.thaniyath@email.com',
        phone: '1234567890',
      );
      final room = Room(
        id: '1',
        number: '101',
        type: 'Deluxe',
        status: 'Occupied',
      );
      final booking = Booking(
        guest: guest,
        room: room,
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(Duration(days: 2)),
        notes: 'Test booking',
      );
      final payments = <Payment>[];

      // Act
      final description = await VertexAIService.generateInvoiceDescription(
        booking,
        payments,
      );

      // Assert
      expect(description, isNotNull);
      expect(description, isNotEmpty);
    });
  });
}
