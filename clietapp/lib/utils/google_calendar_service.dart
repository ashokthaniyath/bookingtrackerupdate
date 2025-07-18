// import 'package:googleapis/calendar/v3.dart' as calendar; // Temporarily disabled
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
// import 'package:url_launcher/url_launcher.dart'; // Temporarily disabled
import '../models/room_calendar_simple.dart';
import '../models/booking.dart';

// Legacy Google Calendar Service for backward compatibility
class GoogleCalendarService {
  Future<List<calendar.Event>> fetchEvents() async {
    // Mock implementation for now
    return [];
  }

  Future<void> addEvent(String title, DateTime start, DateTime end) async {
    // Mock implementation for now
    print('Adding event: $title from $start to $end');
  }
}

class EnhancedGoogleCalendarService {
  static final EnhancedGoogleCalendarService _instance =
      EnhancedGoogleCalendarService._internal();
  factory EnhancedGoogleCalendarService() => _instance;
  EnhancedGoogleCalendarService._internal();

  // New Feature: Room Calendar Management
  final Map<String, RoomCalendar> _roomCalendars = {};
  final Map<String, String> _publicCalendarLinks = {};

  // Initialize with sample room calendars
  void initializeRoomCalendars() {
    _roomCalendars['101'] = RoomCalendar(
      roomId: 'room_101',
      roomNumber: '101',
      roomType: 'Deluxe',
      calendarId: 'deluxe_101@resort.com',
      capacity: 2,
      location: 'Ocean View Wing',
      color: '#4285F4',
    );

    _roomCalendars['102'] = RoomCalendar(
      roomId: 'room_102',
      roomNumber: '102',
      roomType: 'Suite',
      calendarId: 'suite_102@resort.com',
      capacity: 4,
      location: 'Presidential Wing',
      color: '#9C27B0',
    );

    _roomCalendars['103'] = RoomCalendar(
      roomId: 'room_103',
      roomNumber: '103',
      roomType: 'Single',
      calendarId: 'single_103@resort.com',
      capacity: 1,
      location: 'Garden View',
      color: '#4CAF50',
    );

    // Generate mock public links
    for (final room in _roomCalendars.keys) {
      _publicCalendarLinks[room] =
          'https://resort-booking.com/public/calendar/$room';
    }
  }

  // New Feature: Real-time Availability Check
  Future<bool> checkRoomAvailability({
    required String roomNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Mock availability check - simulate conflicts
    final random = DateTime.now().millisecond % 10;
    return random > 3; // 70% availability rate
  }

  // New Feature: Auto-Accept Booking
  Future<bool> createRoomBooking({
    required String roomNumber,
    required Booking booking,
    bool autoAccept = true,
  }) async {
    // Check availability first
    final isAvailable = await checkRoomAvailability(
      roomNumber: roomNumber,
      startTime: booking.checkIn,
      endTime: booking.checkOut,
    );

    if (!isAvailable) return false;

    // Send notification email
    if (autoAccept) {
      await sendBookingNotification(booking, 'confirmation');
    }

    return true;
  }

  // New Feature: Send Notification Emails
  Future<bool> sendBookingNotification(Booking booking, String type) async {
    try {
      final subject = _getEmailSubject(type, booking);
      final body = _getEmailBody(type, booking);
      final emailUrl = Uri(
        scheme: 'mailto',
        path: booking.guest.name, // Assuming this is email
        query:
            'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      return await launchUrl(emailUrl);
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // New Feature: Get Public Calendar Link
  String getPublicCalendarLink(String roomNumber) {
    return _publicCalendarLinks[roomNumber] ??
        'https://resort-booking.com/public/calendar';
  }

  // New Feature: Multi-room Booking
  Future<List<String>> bookMultipleRooms({
    required List<String> roomNumbers,
    required Booking booking,
  }) async {
    final successfulBookings = <String>[];

    for (final roomNumber in roomNumbers) {
      final success = await createRoomBooking(
        roomNumber: roomNumber,
        booking: booking,
      );

      if (success) {
        successfulBookings.add(roomNumber);
      }
    }

    return successfulBookings;
  }

  // Helper methods
  String _getEmailSubject(String type, Booking booking) {
    switch (type) {
      case 'confirmation':
        return 'Booking Confirmation - Room ${booking.room.number}';
      case 'reminder':
        return 'Booking Reminder - Check-in Tomorrow';
      case 'cancellation':
        return 'Booking Cancellation - Room ${booking.room.number}';
      default:
        return 'Booking Update';
    }
  }

  String _getEmailBody(String type, Booking booking) {
    final checkIn =
        '${booking.checkIn.day}/${booking.checkIn.month}/${booking.checkIn.year}';
    final checkOut =
        '${booking.checkOut.day}/${booking.checkOut.month}/${booking.checkOut.year}';

    switch (type) {
      case 'confirmation':
        return 'Dear ${booking.guest.name},\n\nYour booking has been confirmed!\n\nRoom: ${booking.room.number} (${booking.room.type})\nCheck-in: $checkIn\nCheck-out: $checkOut\n\nThank you for choosing our resort!';
      case 'reminder':
        return 'Dear ${booking.guest.name},\n\nThis is a reminder that your check-in is tomorrow.\n\nRoom: ${booking.room.number}\nCheck-in: $checkIn\n\nWe look forward to welcoming you!';
      default:
        return 'Booking update for ${booking.guest.name}';
    }
  }

  // Getters for room calendars
  Map<String, RoomCalendar> get roomCalendars => _roomCalendars;
  List<RoomCalendar> get allRoomCalendars => _roomCalendars.values.toList();
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = IOClient();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}
