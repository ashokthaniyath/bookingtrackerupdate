import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';

/// Event types for real-time updates
enum RealtimeEventType {
  bookingAdded,
  bookingUpdated,
  bookingDeleted,
  roomStatusChanged,
  roomAdded,
  roomUpdated,
  roomDeleted,
  guestAdded,
  guestUpdated,
  guestDeleted,
  paymentAdded,
  paymentUpdated,
  paymentDeleted,
  connectionStatus,
  syncComplete,
  error,
}

/// Event data structure for real-time updates
class RealtimeEvent {
  final RealtimeEventType type;
  final String id;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.id,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Connection status for real-time sync
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Real-time synchronization service for the booking tracker app
/// Provides live updates for bookings, rooms, guests, and payments
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

  // Event stream for real-time updates
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  // Connection status stream
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  // Internal data storage
  List<Booking> _bookings = [];
  List<Room> _rooms = [];
  List<Guest> _guests = [];
  List<Payment> _payments = [];

  // Connection state
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _simulationTimer;
  bool _isSimulationEnabled = false;

  // Getters for streams
  Stream<List<Booking>> get bookingsStream => _bookingsController.stream;
  Stream<List<Room>> get roomsStream => _roomsController.stream;
  Stream<List<Guest>> get guestsStream => _guestsController.stream;
  Stream<List<Payment>> get paymentsStream => _paymentsController.stream;
  Stream<RealtimeEvent> get eventStream => _eventController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;

  // Getters for current data
  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<Room> get rooms => List.unmodifiable(_rooms);
  List<Guest> get guests => List.unmodifiable(_guests);
  List<Payment> get payments => List.unmodifiable(_payments);
  ConnectionStatus get connectionStatus => _connectionStatus;

  /// Initialize the real-time sync service
  Future<void> initialize() async {
    try {
      _setConnectionStatus(ConnectionStatus.connecting);

      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 500));

      _setConnectionStatus(ConnectionStatus.connected);
      _startHeartbeat();

      debugPrint('RealtimeSyncService initialized successfully');
    } catch (e) {
      _setConnectionStatus(ConnectionStatus.error);
      _emitEvent(
        RealtimeEvent(
          type: RealtimeEventType.error,
          id: 'init_error',
          data: {'message': 'Failed to initialize: $e'},
        ),
      );
      debugPrint('RealtimeSyncService initialization failed: $e');
    }
  }

  /// Start real-time simulation
  void startSimulation() {
    if (_isSimulationEnabled) return;

    _isSimulationEnabled = true;
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionStatus == ConnectionStatus.connected) {
        _simulateRandomUpdate();
      }
    });

    debugPrint('Real-time simulation started');
  }

  /// Stop real-time simulation
  void stopSimulation() {
    _isSimulationEnabled = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    debugPrint('Real-time simulation stopped');
  }

  /// Update all data (typically called from ResortDataProvider)
  void updateAllData({
    List<Booking>? bookings,
    List<Room>? rooms,
    List<Guest>? guests,
    List<Payment>? payments,
  }) {
    if (bookings != null) {
      _bookings = List.from(bookings);
      _bookingsController.add(_bookings);
    }

    if (rooms != null) {
      _rooms = List.from(rooms);
      _roomsController.add(_rooms);
    }

    if (guests != null) {
      _guests = List.from(guests);
      _guestsController.add(_guests);
    }

    if (payments != null) {
      _payments = List.from(payments);
      _paymentsController.add(_payments);
    }
  }

  /// Emit a booking event
  void emitBookingEvent(
    RealtimeEventType type,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    _emitEvent(RealtimeEvent(type: type, id: bookingId, data: data));
  }

  /// Emit a room event
  void emitRoomEvent(
    RealtimeEventType type,
    String roomId,
    Map<String, dynamic> data,
  ) {
    _emitEvent(RealtimeEvent(type: type, id: roomId, data: data));
  }

  /// Emit a guest event
  void emitGuestEvent(
    RealtimeEventType type,
    String guestId,
    Map<String, dynamic> data,
  ) {
    _emitEvent(RealtimeEvent(type: type, id: guestId, data: data));
  }

  /// Emit a payment event
  void emitPaymentEvent(
    RealtimeEventType type,
    String paymentId,
    Map<String, dynamic> data,
  ) {
    _emitEvent(RealtimeEvent(type: type, id: paymentId, data: data));
  }

  /// Manual sync operation
  Future<void> manualSync() async {
    try {
      _setConnectionStatus(ConnectionStatus.connecting);

      // Simulate sync delay
      await Future.delayed(const Duration(milliseconds: 800));

      _setConnectionStatus(ConnectionStatus.connected);

      // Emit sync complete event
      _emitEvent(
        RealtimeEvent(
          type: RealtimeEventType.syncComplete,
          id: 'manual_sync',
          data: {'timestamp': DateTime.now().toIso8601String()},
        ),
      );

      debugPrint('Manual sync completed');
    } catch (e) {
      _setConnectionStatus(ConnectionStatus.error);
      _emitEvent(
        RealtimeEvent(
          type: RealtimeEventType.error,
          id: 'sync_error',
          data: {'message': 'Sync failed: $e'},
        ),
      );
    }
  }

  /// Private methods

  void _setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    _connectionController.add(status);

    _emitEvent(
      RealtimeEvent(
        type: RealtimeEventType.connectionStatus,
        id: 'connection',
        data: {'status': status.toString()},
      ),
    );
  }

  void _emitEvent(RealtimeEvent event) {
    _eventController.add(event);
    debugPrint('RealtimeEvent: ${event.type} - ${event.id}');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_connectionStatus == ConnectionStatus.connected) {
        // Simulate occasional disconnection
        if (Random().nextInt(100) < 2) {
          // 2% chance
          _setConnectionStatus(ConnectionStatus.reconnecting);
          Future.delayed(const Duration(seconds: 2), () {
            _setConnectionStatus(ConnectionStatus.connected);
          });
        }
      }
    });
  }

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
        _simulateBookingUpdate();
        break;
      case 3:
        _simulateNewActivity();
        break;
    }
  }

  void _simulateRoomStatusChange() {
    if (_rooms.isEmpty) return;

    final random = Random();
    final room = _rooms[random.nextInt(_rooms.length)];
    final statuses = ['Available', 'Occupied', 'Cleaning', 'Maintenance'];
    final newStatus = statuses[random.nextInt(statuses.length)];

    if (room.status != newStatus) {
      _emitEvent(
        RealtimeEvent(
          type: RealtimeEventType.roomStatusChanged,
          id: room.id ?? 'unknown_room',
          data: {
            'roomNumber': room.number,
            'oldStatus': room.status,
            'newStatus': newStatus,
          },
        ),
      );
    }
  }

  void _simulatePaymentUpdate() {
    if (_payments.isEmpty) return;

    final random = Random();
    final pendingPayments = _payments
        .where((p) => p.status.toLowerCase() == 'pending')
        .toList();

    if (pendingPayments.isNotEmpty) {
      final payment = pendingPayments[random.nextInt(pendingPayments.length)];
      _emitEvent(
        RealtimeEvent(
          type: RealtimeEventType.paymentUpdated,
          id: payment.id ?? 'unknown_payment',
          data: {
            'amount': payment.amount,
            'oldStatus': payment.status,
            'newStatus': 'Paid',
            'guestName': payment.guest.name,
          },
        ),
      );
    }
  }

  void _simulateBookingUpdate() {
    if (_bookings.isEmpty) return;

    final random = Random();
    final booking = _bookings[random.nextInt(_bookings.length)];

    _emitEvent(
      RealtimeEvent(
        type: RealtimeEventType.bookingUpdated,
        id: booking.id ?? 'unknown_booking',
        data: {
          'guestName': booking.guest.name,
          'roomNumber': booking.room.number,
          'checkIn': booking.checkIn.toIso8601String(),
          'checkOut': booking.checkOut.toIso8601String(),
          'notes': 'Updated via real-time sync',
        },
      ),
    );
  }

  void _simulateNewActivity() {
    final random = Random();
    final activityTypes = [
      'New booking inquiry',
      'Guest checked in',
      'Guest checked out',
      'Room maintenance completed',
      'Payment received',
    ];

    final activity = activityTypes[random.nextInt(activityTypes.length)];

    _emitEvent(
      RealtimeEvent(
        type: RealtimeEventType.bookingAdded,
        id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'activity': activity,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Cleanup and dispose
  void dispose() {
    _heartbeatTimer?.cancel();
    _simulationTimer?.cancel();

    _bookingsController.close();
    _roomsController.close();
    _guestsController.close();
    _paymentsController.close();
    _eventController.close();
    _connectionController.close();

    debugPrint('RealtimeSyncService disposed');
  }
}
