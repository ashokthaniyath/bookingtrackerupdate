import 'dart:async';
import '../config/app_config.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/payment.dart';

class ProductionFirebaseService {
  static bool _isInitialized = false;

  // Mock data for development until Firebase is connected
  static final List<Guest> _mockGuests = [
    Guest(
      name: 'Shajil Thaniyath',
      email: 'shajil@example.com',
      phone: '+1234567890',
    ),
    Guest(
      name: 'Ashok Thaniyath',
      email: 'ashok@example.com',
      phone: '+1234567891',
    ),
    Guest(name: 'John Doe', email: 'john@example.com', phone: '+1234567892'),
    Guest(name: 'Jane Smith', email: 'jane@example.com', phone: '+1234567893'),
  ];

  static final List<Room> _mockRooms = [
    Room(number: '101', type: 'Standard', status: 'Available'),
    Room(number: '102', type: 'Deluxe', status: 'Available'),
    Room(number: '103', type: 'Suite', status: 'Available'),
    Room(number: '104', type: 'Standard', status: 'Available'),
    Room(number: '105', type: 'Deluxe', status: 'Available'),
  ];

  static final List<Booking> _mockBookings = [];
  static final List<Payment> _mockPayments = [];

  // Stream controllers for real-time updates
  static final StreamController<List<Guest>> _guestsController =
      StreamController<List<Guest>>.broadcast();
  static final StreamController<List<Room>> _roomsController =
      StreamController<List<Room>>.broadcast();
  static final StreamController<List<Booking>> _bookingsController =
      StreamController<List<Booking>>.broadcast();
  static final StreamController<List<Payment>> _paymentsController =
      StreamController<List<Payment>>.broadcast();

  // Stream getters
  static Stream<List<Guest>> get guestsStream => _guestsController.stream;
  static Stream<List<Room>> get roomsStream => _roomsController.stream;
  static Stream<List<Booking>> get bookingsStream => _bookingsController.stream;
  static Stream<List<Payment>> get paymentsStream => _paymentsController.stream;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing Production Firebase Service...');

      if (AppConfig.useFirebase && AppConfig.isConfigured) {
        // TODO: Initialize real Firebase
        // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        print('✅ Firebase initialized (Production mode)');
      } else {
        print('⚠️  Using mock data - Firebase not configured');
      }

      _isInitialized = true;

      // Start mock data streams
      _startMockDataStreams();
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      _isInitialized = false;
    }
  }

  static void _startMockDataStreams() {
    // Simulate real-time updates every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _guestsController.add(_mockGuests);
      _roomsController.add(_mockRooms);
      _bookingsController.add(_mockBookings);
      _paymentsController.add(_mockPayments);
    });
  }

  // Guest operations
  static Future<List<Guest>> getGuests() async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Get from Firestore
      // return await FirebaseFirestore.instance.collection('guests').get();
    }

    return _mockGuests;
  }

  static Future<void> addGuest(Guest guest) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Add to Firestore
      // await FirebaseFirestore.instance.collection('guests').add(guest.toMap());
    }

    _mockGuests.add(guest);
    _guestsController.add(_mockGuests);
  }

  static Future<void> updateGuest(Guest guest) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Update in Firestore
    }

    final index = _mockGuests.indexWhere((g) => g.name == guest.name);
    if (index != -1) {
      _mockGuests[index] = guest;
      _guestsController.add(_mockGuests);
    }
  }

  static Future<void> deleteGuest(String guestName) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Delete from Firestore
    }

    _mockGuests.removeWhere((g) => g.name == guestName);
    _guestsController.add(_mockGuests);
  }

  // Room operations
  static Future<List<Room>> getRooms() async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Get from Firestore
    }

    return _mockRooms;
  }

  static Future<void> addRoom(Room room) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Add to Firestore
    }

    _mockRooms.add(room);
    _roomsController.add(_mockRooms);
  }

  static Future<void> updateRoom(Room room) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Update in Firestore
    }

    final index = _mockRooms.indexWhere((r) => r.number == room.number);
    if (index != -1) {
      _mockRooms[index] = room;
      _roomsController.add(_mockRooms);
    }
  }

  static Future<void> updateRoomStatus(String roomNumber, String status) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Update in Firestore
    }

    final index = _mockRooms.indexWhere((r) => r.number == roomNumber);
    if (index != -1) {
      _mockRooms[index] = Room(
        number: _mockRooms[index].number,
        type: _mockRooms[index].type,
        status: status,
      );
      _roomsController.add(_mockRooms);
    }
  }

  // Booking operations
  static Future<List<Booking>> getBookings() async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Get from Firestore
    }

    return _mockBookings;
  }

  static Future<void> addBooking(Booking booking) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Add to Firestore
    }

    _mockBookings.add(booking);
    _bookingsController.add(_mockBookings);
  }

  static Future<void> updateBooking(Booking booking) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Update in Firestore
    }

    final index = _mockBookings.indexWhere(
      (b) =>
          b.guest.name == booking.guest.name &&
          b.room.number == booking.room.number,
    );
    if (index != -1) {
      _mockBookings[index] = booking;
      _bookingsController.add(_mockBookings);
    }
  }

  static Future<void> deleteBooking(String guestName, String roomNumber) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Delete from Firestore
    }

    _mockBookings.removeWhere(
      (b) => b.guest.name == guestName && b.room.number == roomNumber,
    );
    _bookingsController.add(_mockBookings);
  }

  // Payment operations
  static Future<List<Payment>> getPayments() async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Get from Firestore
    }

    return _mockPayments;
  }

  static Future<void> addPayment(Payment payment) async {
    await _ensureInitialized();

    if (AppConfig.useFirebase && AppConfig.isConfigured) {
      // TODO: Add to Firestore
    }

    _mockPayments.add(payment);
    _paymentsController.add(_mockPayments);
  }

  // Error logging method
  static Future<void> logError(dynamic errorLog) async {
    try {
      if (AppConfig.useFirebase) {
        // TODO: Send to Firebase Analytics/Crashlytics
        print('🔥 Logging error to Firebase: ${errorLog.toString()}');
      } else {
        print('📝 Error logged locally: ${errorLog.toString()}');
      }
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  // Utility methods
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  static Future<void> dispose() async {
    await _guestsController.close();
    await _roomsController.close();
    await _bookingsController.close();
    await _paymentsController.close();
  }

  // Network connectivity check
  static Future<bool> isConnected() async {
    if (AppConfig.useFirebase) {
      // TODO: Check Firebase connection
      return true;
    }
    return true; // Mock mode always connected
  }

  // Sync data from cache
  static Future<void> syncFromCache() async {
    // TODO: Implement cache sync
    print('📱 Syncing data from cache...');
  }

  // Sync data to cache
  static Future<void> syncToCache() async {
    // TODO: Implement cache sync
    print('💾 Syncing data to cache...');
  }
}
