import 'dart:async';
import '../config/app_config.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import 'production_firebase_service.dart';

class ProductionCalendarService {
  static bool _isInitialized = false;
  static Timer? _syncTimer;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing Production Calendar Service...');

      if (AppConfig.enableCalendarAI) {
        // Start periodic sync with Firebase
        _startPeriodicSync();
        print('✅ Calendar AI initialized (Production mode)');
      } else {
        print('⚠️  Calendar AI disabled - using mock data');
      }

      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing calendar service: $e');
      _isInitialized = false;
    }
  }

  static void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _syncCalendarData();
      } catch (e) {
        print('❌ Calendar sync failed: $e');
      }
    });
  }

  static Future<void> _syncCalendarData() async {
    if (!AppConfig.enableCalendarAI || !AppConfig.isConfigured) return;

    try {
      print('🔄 Syncing calendar data...');

      // Get all bookings from Firebase
      final bookings = await ProductionFirebaseService.getBookings();

      // Process bookings for calendar optimization
      await _processBookingsForCalendar(bookings);

      print('✅ Calendar sync completed');
    } catch (e) {
      print('❌ Calendar sync error: $e');
    }
  }

  static Future<void> _processBookingsForCalendar(
    List<Booking> bookings,
  ) async {
    // TODO: Implement calendar optimization logic
    // This would analyze booking patterns and suggest optimizations
    for (final booking in bookings) {
      // Process each booking for calendar insights
      print(
        '📅 Processing booking: ${booking.guest.name} - ${booking.room.number}',
      );
    }
  }

  static Future<List<RoomCalendarData>> getRoomCalendars() async {
    await _ensureInitialized();

    try {
      if (AppConfig.enableCalendarAI && AppConfig.isConfigured) {
        return await _getRealRoomCalendars();
      } else {
        return await _getMockRoomCalendars();
      }
    } catch (e) {
      print('❌ Error getting room calendars: $e');
      return await _getMockRoomCalendars();
    }
  }

  static Future<List<RoomCalendarData>> _getRealRoomCalendars() async {
    try {
      // Get rooms and bookings from Firebase
      final rooms = await ProductionFirebaseService.getRooms();
      final bookings = await ProductionFirebaseService.getBookings();

      // Convert to calendar format
      final calendars = <RoomCalendarData>[];

      for (final room in rooms) {
        final roomBookings = bookings
            .where((b) => b.room.number == room.number)
            .toList();

        final calendar = RoomCalendarData(
          roomNumber: room.number,
          roomType: room.type,
          bookings: roomBookings,
          availability: _calculateAvailability(roomBookings),
          nextCheckIn: _getNextCheckIn(roomBookings),
          nextCheckOut: _getNextCheckOut(roomBookings),
          occupancyRate: _calculateOccupancyRate(roomBookings),
          revenue: _calculateRevenue(roomBookings),
        );

        calendars.add(calendar);
      }

      return calendars;
    } catch (e) {
      print('❌ Real calendar fetch failed: $e');
      return await _getMockRoomCalendars();
    }
  }

  static Future<List<RoomCalendarData>> _getMockRoomCalendars() async {
    // Mock data for testing
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      RoomCalendarData(
        roomNumber: '101',
        roomType: 'Standard',
        bookings: [
          Booking(
            guest: Guest(name: 'John Doe', email: 'john@example.com'),
            room: Room(number: '101', type: 'Standard', status: 'booked'),
            checkIn: today,
            checkOut: today.add(const Duration(days: 2)),
            notes: 'Late check-in',
            depositPaid: true,
            paymentStatus: 'paid',
          ),
        ],
        availability: _generateMockAvailability(),
        nextCheckIn: today.add(const Duration(hours: 2)),
        nextCheckOut: today.add(const Duration(days: 1, hours: 11)),
        occupancyRate: 0.75,
        revenue: 1500.0,
      ),
      RoomCalendarData(
        roomNumber: '102',
        roomType: 'Deluxe',
        bookings: [],
        availability: _generateMockAvailability(),
        nextCheckIn: null,
        nextCheckOut: null,
        occupancyRate: 0.0,
        revenue: 0.0,
      ),
    ];
  }

  static List<DateTime> _generateMockAvailability() {
    final now = DateTime.now();
    final available = <DateTime>[];

    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      if (i % 3 != 0) {
        // Mock 2/3 availability
        available.add(date);
      }
    }

    return available;
  }

  static List<DateTime> _calculateAvailability(List<Booking> bookings) {
    final now = DateTime.now();
    final available = <DateTime>[];

    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final hasBooking = bookings.any(
        (booking) =>
            date.isAfter(booking.checkIn.subtract(const Duration(days: 1))) &&
            date.isBefore(booking.checkOut),
      );

      if (!hasBooking) {
        available.add(date);
      }
    }

    return available;
  }

  static DateTime? _getNextCheckIn(List<Booking> bookings) {
    final now = DateTime.now();
    final upcomingBookings =
        bookings.where((b) => b.checkIn.isAfter(now)).toList()
          ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    return upcomingBookings.isNotEmpty ? upcomingBookings.first.checkIn : null;
  }

  static DateTime? _getNextCheckOut(List<Booking> bookings) {
    final now = DateTime.now();
    final currentBookings =
        bookings
            .where((b) => b.checkIn.isBefore(now) && b.checkOut.isAfter(now))
            .toList()
          ..sort((a, b) => a.checkOut.compareTo(b.checkOut));

    return currentBookings.isNotEmpty ? currentBookings.first.checkOut : null;
  }

  static double _calculateOccupancyRate(List<Booking> bookings) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recentBookings = bookings.where(
      (b) => b.checkIn.isAfter(last30Days) || b.checkOut.isAfter(last30Days),
    );

    // Calculate occupied days in last 30 days
    int occupiedDays = 0;
    for (int i = 0; i < 30; i++) {
      final date = last30Days.add(Duration(days: i));
      final hasBooking = recentBookings.any(
        (booking) =>
            date.isAfter(booking.checkIn.subtract(const Duration(days: 1))) &&
            date.isBefore(booking.checkOut),
      );
      if (hasBooking) occupiedDays++;
    }

    return occupiedDays / 30.0;
  }

  static double _calculateRevenue(List<Booking> bookings) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    return bookings.where((b) => b.checkIn.isAfter(last30Days)).fold(0.0, (
      sum,
      booking,
    ) {
      final nights = booking.checkOut.difference(booking.checkIn).inDays;
      return sum + (booking.room.pricePerNight * nights);
    });
  }

  static Future<List<CalendarOptimization>> getOptimizationSuggestions() async {
    await _ensureInitialized();

    try {
      if (AppConfig.enableCalendarAI && AppConfig.isConfigured) {
        return await _getRealOptimizations();
      } else {
        return await _getMockOptimizations();
      }
    } catch (e) {
      print('❌ Error getting optimization suggestions: $e');
      return await _getMockOptimizations();
    }
  }

  static Future<List<CalendarOptimization>> _getRealOptimizations() async {
    try {
      // TODO: Implement AI-powered optimization analysis
      // This would use machine learning to suggest calendar optimizations
      return await _getMockOptimizations();
    } catch (e) {
      print('❌ Real optimization failed: $e');
      return await _getMockOptimizations();
    }
  }

  static Future<List<CalendarOptimization>> _getMockOptimizations() async {
    return [
      CalendarOptimization(
        type: 'pricing',
        title: 'Adjust Weekend Pricing',
        description: 'Increase weekend rates by 15% to maximize revenue',
        priority: 'high',
        impact: 'Revenue increase: +\$2,400/month',
        action: 'Update pricing for Friday-Sunday',
      ),
      CalendarOptimization(
        type: 'scheduling',
        title: 'Optimize Housekeeping Schedule',
        description: 'Adjust cleaning times to reduce guest wait times',
        priority: 'medium',
        impact: 'Reduce check-in delays by 20%',
        action: 'Reschedule housekeeping to 10 AM',
      ),
      CalendarOptimization(
        type: 'booking',
        title: 'Enable Overbooking Protection',
        description: 'Set up 5% overbooking buffer for high-demand periods',
        priority: 'low',
        impact: 'Increase bookings by 3-5%',
        action: 'Configure overbooking settings',
      ),
    ];
  }

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  static Future<void> dispose() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isInitialized = false;
  }
}

class CalendarOptimization {
  final String type;
  final String title;
  final String description;
  final String priority;
  final String impact;
  final String action;

  CalendarOptimization({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.impact,
    required this.action,
  });
}

class RoomCalendarData {
  final String roomNumber;
  final String roomType;
  final List<Booking> bookings;
  final List<DateTime> availability;
  final DateTime? nextCheckIn;
  final DateTime? nextCheckOut;
  final double occupancyRate;
  final double revenue;

  RoomCalendarData({
    required this.roomNumber,
    required this.roomType,
    required this.bookings,
    required this.availability,
    this.nextCheckIn,
    this.nextCheckOut,
    required this.occupancyRate,
    required this.revenue,
  });
}
