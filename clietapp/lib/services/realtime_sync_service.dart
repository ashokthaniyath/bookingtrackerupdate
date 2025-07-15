import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';

/// Real-time synchronization service for the booking tracker app
/// Provides local real-time updates and can be extended for backend sync
class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();

  // Stream controllers for different data types
  final StreamController<List<Booking>> _bookingsController =
      StreamController<List<Booking>>.broadcast();
  final StreamController<List<Room>> _roomsController =
      StreamController<List<Room>>.broadcast();
  final StreamController<List<Guest>> _guestsController =
      StreamController<List<Guest>>.broadcast();
  final StreamController<List<Payment>> _paymentsController =
      StreamController<List<Payment>>.broadcast();

  // Event stream for real-time notifications
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  // Timers for simulating real-time updates
  Timer? _simulationTimer;
  Timer? _heartbeatTimer;

  // Connection status
  bool _isConnected = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Data cache
  List<Booking> _cachedBookings = [];
  List<Room> _cachedRooms = [];
  List<Guest> _cachedGuests = [];
  List<Payment> _cachedPayments = [];

  // Getters for streams
  Stream<List<Booking>> get bookingsStream => _bookingsController.stream;
  Stream<List<Room>> get roomsStream => _roomsController.stream;
  Stream<List<Guest>> get guestsStream => _guestsController.stream;
  Stream<List<Payment>> get paymentsStream => _paymentsController.stream;
  Stream<RealtimeEvent> get eventsStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Initialize the real-time service
  void initialize() {
    debugPrint('🔄 RealtimeSyncService: Initializing...');
    _startConnection();
    _startHeartbeat();
    _startSimulation();
  }

  /// Start the connection simulation
  void _startConnection() {
    _isConnected = true;
    _connectionController.add(_isConnected);
    _eventController.add(
      RealtimeEvent(
        type: RealtimeEventType.connected,
        message: 'Real-time sync connected',
        timestamp: DateTime.now(),
      ),
    );
    debugPrint('✅ RealtimeSyncService: Connected');
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _eventController.add(
          RealtimeEvent(
            type: RealtimeEventType.heartbeat,
            message: 'Connection alive',
            timestamp: DateTime.now(),
          ),
        );
        debugPrint('💓 RealtimeSyncService: Heartbeat');
      }
    });
  }

  /// Start simulation of real-time updates
  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_isConnected) {
        _simulateRandomUpdate();
      }
    });
  }

  /// Simulate random updates for demonstration
  void _simulateRandomUpdate() {
    final random = Random();
    final updateType = random.nextInt(4);

    switch (updateType) {
      case 0:
        _simulateRoomStatusChange();
        break;
      case 1:
        _simulatePaymentUpdate();
        break;
      case 2:
        _simulateNewBooking();
        break;
      case 3:
        _simulateCheckInOut();
        break;
    }
  }

  /// Simulate a room status change
  void _simulateRoomStatusChange() {
    if (_cachedRooms.isNotEmpty) {
      final random = Random();
      final room = _cachedRooms[random.nextInt(_cachedRooms.length)];
      final statuses = ['Available', 'Occupied', 'Cleaning', 'Maintenance'];
      final newStatus = statuses[random.nextInt(statuses.length)];

      if (room.status != newStatus) {
        final updatedRoom = Room(
          id: room.id,
          number: room.number,
          type: room.type,
          status: newStatus,
        );

        updateRoom(updatedRoom);

        _eventController.add(
          RealtimeEvent(
            type: RealtimeEventType.roomUpdated,
            message: 'Room ${room.number} status changed to $newStatus',
            timestamp: DateTime.now(),
            data: {'roomId': room.id, 'newStatus': newStatus},
          ),
        );
      }
    }
  }

  /// Simulate a payment update
  void _simulatePaymentUpdate() {
    if (_cachedPayments.isNotEmpty) {
      final random = Random();
      final pendingPayments = _cachedPayments
          .where((p) => p.status.toLowerCase() == 'pending')
          .toList();

      if (pendingPayments.isNotEmpty) {
        final payment = pendingPayments[random.nextInt(pendingPayments.length)];
        final updatedPayment = Payment(
          id: payment.id,
          guest: payment.guest,
          amount: payment.amount,
          status: 'Paid',
          date: payment.date,
        );

        updatePayment(updatedPayment);

        _eventController.add(
          RealtimeEvent(
            type: RealtimeEventType.paymentUpdated,
            message:
                'Payment of ₹${payment.amount} from ${payment.guest.name} was processed',
            timestamp: DateTime.now(),
            data: {'paymentId': payment.id, 'amount': payment.amount},
          ),
        );
      }
    }
  }

  /// Simulate a new booking
  void _simulateNewBooking() {
    final random = Random();
    final availableRooms = _cachedRooms
        .where((r) => r.status.toLowerCase() == 'available')
        .toList();

    if (availableRooms.isNotEmpty && _cachedGuests.isNotEmpty) {
      final room = availableRooms[random.nextInt(availableRooms.length)];
      final guest = _cachedGuests[random.nextInt(_cachedGuests.length)];

      final newBooking = Booking(
        id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        guest: guest,
        room: room,
        checkIn: DateTime.now().add(Duration(days: random.nextInt(30) + 1)),
        checkOut: DateTime.now().add(Duration(days: random.nextInt(30) + 3)),
        notes: 'Auto-generated booking',
      );

      addBooking(newBooking);

      _eventController.add(
        RealtimeEvent(
          type: RealtimeEventType.bookingAdded,
          message: 'New booking: ${guest.name} in room ${room.number}',
          timestamp: DateTime.now(),
          data: {
            'bookingId': newBooking.id,
            'guestName': guest.name,
            'roomNumber': room.number,
          },
        ),
      );
    }
  }

  /// Simulate check-in/check-out
  void _simulateCheckInOut() {
    final random = Random();
    final today = DateTime.now();

    // Find bookings that should check in today
    final checkInToday = _cachedBookings
        .where(
          (b) =>
              b.checkIn.year == today.year &&
              b.checkIn.month == today.month &&
              b.checkIn.day == today.day,
        )
        .toList();

    if (checkInToday.isNotEmpty && random.nextBool()) {
      final booking = checkInToday[random.nextInt(checkInToday.length)];
      final updatedRoom = Room(
        id: booking.room.id,
        number: booking.room.number,
        type: booking.room.type,
        status: 'Occupied',
      );

      updateRoom(updatedRoom);

      _eventController.add(
        RealtimeEvent(
          type: RealtimeEventType.checkIn,
          message:
              '${booking.guest.name} checked into room ${booking.room.number}',
          timestamp: DateTime.now(),
          data: {
            'guestName': booking.guest.name,
            'roomNumber': booking.room.number,
          },
        ),
      );
    }
  }

  /// Update data and notify listeners
  void updateBookings(List<Booking> bookings) {
    _cachedBookings = List.from(bookings);
    _bookingsController.add(_cachedBookings);
  }

  void updateRooms(List<Room> rooms) {
    _cachedRooms = List.from(rooms);
    _roomsController.add(_cachedRooms);
  }

  void updateGuests(List<Guest> guests) {
    _cachedGuests = List.from(guests);
    _guestsController.add(_cachedGuests);
  }

  void updatePayments(List<Payment> payments) {
    _cachedPayments = List.from(payments);
    _paymentsController.add(_cachedPayments);
  }

  /// Add individual items
  void addBooking(Booking booking) {
    _cachedBookings.add(booking);
    _bookingsController.add(_cachedBookings);
  }

  void addRoom(Room room) {
    _cachedRooms.add(room);
    _roomsController.add(_cachedRooms);
  }

  void addGuest(Guest guest) {
    _cachedGuests.add(guest);
    _guestsController.add(_cachedGuests);
  }

  void addPayment(Payment payment) {
    _cachedPayments.add(payment);
    _paymentsController.add(_cachedPayments);
  }

  /// Update individual items
  void updateBooking(Booking booking) {
    final index = _cachedBookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _cachedBookings[index] = booking;
      _bookingsController.add(_cachedBookings);
    }
  }

  void updateRoom(Room room) {
    final index = _cachedRooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _cachedRooms[index] = room;
      _roomsController.add(_cachedRooms);
    }
  }

  void updateGuest(Guest guest) {
    final index = _cachedGuests.indexWhere((g) => g.id == guest.id);
    if (index != -1) {
      _cachedGuests[index] = guest;
      _guestsController.add(_cachedGuests);
    }
  }

  void updatePayment(Payment payment) {
    final index = _cachedPayments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      _cachedPayments[index] = payment;
      _paymentsController.add(_cachedPayments);
    }
  }

  /// Remove individual items
  void removeBooking(String id) {
    _cachedBookings.removeWhere((b) => b.id == id);
    _bookingsController.add(_cachedBookings);
  }

  void removeRoom(String id) {
    _cachedRooms.removeWhere((r) => r.id == id);
    _roomsController.add(_cachedRooms);
  }

  void removeGuest(String id) {
    _cachedGuests.removeWhere((g) => g.id == id);
    _guestsController.add(_cachedGuests);
  }

  void removePayment(String id) {
    _cachedPayments.removeWhere((p) => p.id == id);
    _paymentsController.add(_cachedPayments);
  }

  /// Manually trigger a sync
  void forceSync() {
    _eventController.add(
      RealtimeEvent(
        type: RealtimeEventType.syncRequested,
        message: 'Manual sync requested',
        timestamp: DateTime.now(),
      ),
    );

    // Emit current data to refresh all listeners
    _bookingsController.add(_cachedBookings);
    _roomsController.add(_cachedRooms);
    _guestsController.add(_cachedGuests);
    _paymentsController.add(_cachedPayments);

    debugPrint('🔄 RealtimeSyncService: Manual sync completed');
  }

  /// Disconnect the service
  void disconnect() {
    _isConnected = false;
    _connectionController.add(_isConnected);
    _simulationTimer?.cancel();
    _heartbeatTimer?.cancel();

    _eventController.add(
      RealtimeEvent(
        type: RealtimeEventType.disconnected,
        message: 'Real-time sync disconnected',
        timestamp: DateTime.now(),
      ),
    );

    debugPrint('❌ RealtimeSyncService: Disconnected');
  }

  /// Reconnect the service
  void reconnect() {
    disconnect();
    Future.delayed(const Duration(seconds: 2), () {
      initialize();
    });
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _bookingsController.close();
    _roomsController.close();
    _guestsController.close();
    _paymentsController.close();
    _eventController.close();
    _connectionController.close();
  }
}

/// Real-time event types
enum RealtimeEventType {
  connected,
  disconnected,
  heartbeat,
  syncRequested,
  bookingAdded,
  bookingUpdated,
  roomUpdated,
  paymentUpdated,
  checkIn,
  checkOut,
  error,
}

/// Real-time event model
class RealtimeEvent {
  final RealtimeEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  RealtimeEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data,
  });

  @override
  String toString() {
    return 'RealtimeEvent(type: $type, message: $message, timestamp: $timestamp)';
  }
}
