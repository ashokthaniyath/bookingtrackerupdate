import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// Firebase temporarily disabled
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import '../utils/realtime_sync_service.dart';

class ResortDataProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  List<Room> _rooms = [];
  List<Guest> _guests = [];
  List<Payment> _payments = [];

  // Real-time sync service
  final RealtimeSyncService _realtimeService = RealtimeSyncService();
  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;

  // Getters
  List<Booking> get bookings => _bookings;
  List<Room> get rooms => _rooms;
  List<Guest> get guests => _guests;
  List<Payment> get payments => _payments;
  bool get isInitialized => _isInitialized;
  bool get hasData => _rooms.isNotEmpty && _guests.isNotEmpty;

  // Protected setters for subclasses
  @protected
  set bookings(List<Booking> value) => _bookings = value;
  @protected
  set rooms(List<Room> value) => _rooms = value;
  @protected
  set guests(List<Guest> value) => _guests = value;
  @protected
  set payments(List<Payment> value) => _payments = value;

  // Real-time service access
  RealtimeSyncService get realtimeService => _realtimeService;
  bool get isRealtimeConnected =>
      _realtimeService.connectionStatus == ConnectionStatus.connected;

  // Statistics getters
  int get totalRooms => _rooms.length;
  int get availableRooms =>
      _rooms.where((r) => r.status.toLowerCase() == 'available').length;
  int get occupiedRooms =>
      _rooms.where((r) => r.status.toLowerCase() == 'occupied').length;
  int get cleaningRooms =>
      _rooms.where((r) => r.status.toLowerCase() == 'cleaning').length;
  int get maintenanceRooms =>
      _rooms.where((r) => r.status.toLowerCase() == 'maintenance').length;
  int get totalGuests => _guests.length;

  // Analytics calculations
  double get occupancyRate {
    if (totalRooms == 0) return 0.0;
    return (occupiedRooms / totalRooms) * 100;
  }

  double get totalRevenue {
    return _payments
        .where((p) => p.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get pendingRevenue {
    return _payments
        .where((p) => p.status.toLowerCase() == 'pending')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get totalOutstanding {
    return _payments
        .where((p) => p.status.toLowerCase() == 'overdue')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // Analytics for charts
  Map<String, double> get roomStatusData {
    return {
      'Available': availableRooms.toDouble(),
      'Occupied': occupiedRooms.toDouble(),
      'Cleaning': cleaningRooms.toDouble(),
      'Maintenance': maintenanceRooms.toDouble(),
    };
  }

  List<Map<String, dynamic>> get revenueData {
    // Group payments by month for the last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - index, 1);
      return month;
    }).reversed.toList();

    return months.map((month) {
      final monthPayments = _payments.where(
        (p) =>
            p.date.year == month.year &&
            p.date.month == month.month &&
            p.status.toLowerCase() == 'paid',
      );
      final revenue = monthPayments.fold(0.0, (sum, p) => sum + p.amount);
      return {'month': '${month.month}/${month.year}', 'revenue': revenue};
    }).toList();
  }

  // Local data initialization with sample data
  Future<void> loadData() async {
    try {
      await _loadSampleData();

      // Initialize real-time service if not already done
      if (!_isInitialized) {
        await _initializeRealtimeService();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  // Load data from Firebase - Real data mode
  Future<void> loadDataFromFirebase() async {
    try {
      debugPrint('🔄 Loading real data from Firebase...');

      // Initialize real-time service if not already done
      if (!_isInitialized) {
        await _initializeRealtimeService();
      }

      // Load real data from Firebase collections
      await _loadRealDataFromFirestore();

      debugPrint('✅ Real data loaded successfully from Firebase');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading real data from Firebase: $e');
      // Always use sample data as fallback if Firebase fails or returns insufficient data
      try {
        await _loadSampleData();
        debugPrint(
          '⚠️ Fallback to sample data due to Firebase error or missing data',
        );
        notifyListeners();
      } catch (fallbackError) {
        debugPrint('❌ Failed to load fallback data: $fallbackError');
      }
    }

    // Final check: ensure we have critical data, otherwise load sample data
    if (_rooms.isEmpty || _guests.isEmpty) {
      try {
        debugPrint(
          '🔧 Final check: Loading sample data due to missing critical data',
        );
        await _loadSampleData();
        notifyListeners();
      } catch (e) {
        debugPrint('❌ Failed to load sample data in final check: $e');
      }
    }
  }

  /// Load real data from Firestore collections - temporarily disabled
  Future<void> _loadRealDataFromFirestore() async {
    // Firebase temporarily disabled - using sample data only
    debugPrint('🔄 Firebase disabled, using sample data instead');
    await _loadSampleData();
    return;

    /*
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Load guests first since other entities depend on them
      final guestsSnapshot = await firestore.collection('guests').get();
      _guests = guestsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Guest(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
        );
      }).toList();

      debugPrint('📋 Loaded ${_guests.length} guests from Firestore');

      // Load rooms
      final roomsSnapshot = await firestore.collection('rooms').get();
      _rooms = roomsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Room(
          id: doc.id,
          number: data['number'] ?? '',
          type: data['type'] ?? 'Standard',
          status: data['status'] ?? 'Available',
        );
      }).toList();

      debugPrint('🏠 Loaded ${_rooms.length} rooms from Firestore');

      // Load payments
      final paymentsSnapshot = await firestore.collection('payments').get();
      _payments = paymentsSnapshot.docs.map((doc) {
        final data = doc.data();
        // Find corresponding guest
        final guest = _guests.firstWhere(
          (g) => g.id == data['guestId'],
          orElse: () =>
              Guest(id: '', name: 'Unknown Guest', email: '', phone: ''),
        );

        return Payment(
          id: doc.id,
          guest: guest,
          amount: (data['amount'] ?? 0.0).toDouble(),
          status: data['status'] ?? 'Pending',
          date: data['date'] != null
              ? DateTime.parse(data['date'])
              : DateTime.now(),
        );
      }).toList();

      debugPrint('💰 Loaded ${_payments.length} payments from Firestore');

      // Load bookings
      final bookingsSnapshot = await firestore.collection('bookings').get();
      _bookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        // Find corresponding guest and room
        final guest = _guests.firstWhere(
          (g) => g.id == data['guestId'],
          orElse: () =>
              Guest(id: '', name: 'Unknown Guest', email: '', phone: ''),
        );
        final room = _rooms.firstWhere(
          (r) => r.id == data['roomId'],
          orElse: () => Room(
            id: '',
            number: '000',
            type: 'Standard',
            status: 'Available',
          ),
        );

        return Booking(
          id: doc.id,
          guest: guest,
          room: room,
          checkIn: data['checkIn'] != null
              ? DateTime.parse(data['checkIn'])
              : DateTime.now(),
          checkOut: data['checkOut'] != null
              ? DateTime.parse(data['checkOut'])
              : DateTime.now().add(const Duration(days: 1)),
          notes: data['notes'] ?? '',
          paymentStatus: data['paymentStatus'] ?? 'Pending',
        );
      }).toList();

      debugPrint('📅 Loaded ${_bookings.length} bookings from Firestore');

      // If critical data is missing (especially rooms), set up sample data
      if (_rooms.isEmpty || _guests.isEmpty) {
        debugPrint(
          '📝 Critical data missing from Firestore (${_rooms.length} rooms, ${_guests.length} guests). Setting up sample data...',
        );
        await _setupInitialData();
      }
    } catch (e) {
      debugPrint('❌ Error loading real data from Firestore: $e');
      rethrow;
    }
    */
  }

  /// Set up initial sample data for first-time users (uploads to Firebase)
  Future<void> _setupInitialData() async {
    try {
      // Load sample data locally first
      await _loadSampleData();

      // Upload to Firebase for persistence
      await _uploadSampleDataToFirebase();

      debugPrint(
        '✅ Initial sample data setup complete and uploaded to Firebase',
      );
    } catch (e) {
      debugPrint('❌ Error setting up initial data: $e');
      rethrow;
    }
  }

  /// Method to clear all data and start fresh (for testing) - temporarily disabled
  Future<void> clearAllDataAndStartFresh() async {
    // Firebase temporarily disabled - only clear local data
    _bookings.clear();
    _rooms.clear();
    _guests.clear();
    _payments.clear();
    notifyListeners();
    debugPrint('🗑️ Local data cleared (Firebase disabled)');
    return;

    /*
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Clear local data
      _bookings.clear();
      _rooms.clear();
      _guests.clear();
      _payments.clear();

      // Clear Firestore collections
      final batch = firestore.batch();

      // Delete all documents in each collection
      final collections = ['bookings', 'rooms', 'guests', 'payments'];
      for (final collectionName in collections) {
        final snapshot = await firestore.collection(collectionName).get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      // Set up fresh sample data
      await _setupInitialData();

      notifyListeners();
      debugPrint('🗑️ All data cleared and fresh sample data loaded');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
    */
  }

  Future<void> _uploadSampleDataToFirebase() async {
    // Firebase temporarily disabled
    debugPrint('🔄 Firebase disabled, skipping upload');
    return;

    /*
    // Import Firebase packages
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Upload guests
    for (final guest in _guests) {
      await firestore.collection('guests').doc(guest.id).set({
        'name': guest.name,
        'email': guest.email,
        'phone': guest.phone,
      });
    }

    // Upload rooms
    for (final room in _rooms) {
      await firestore.collection('rooms').doc(room.id).set({
        'number': room.number,
        'type': room.type,
        'status': room.status,
      });
    }

    // Upload bookings
    for (final booking in _bookings) {
      await firestore.collection('bookings').doc(booking.id).set({
        'guestId': booking.guest.id,
        'roomId': booking.room.id,
        'checkIn': booking.checkIn.toIso8601String(),
        'checkOut': booking.checkOut.toIso8601String(),
        'notes': booking.notes,
        'paymentStatus': booking.paymentStatus,
      });
    }

    // Upload payments
    for (final payment in _payments) {
      await firestore.collection('payments').doc(payment.id).set({
        'guestId': payment.guest.id,
        'amount': payment.amount,
        'status': payment.status,
        'date': payment.date.toIso8601String(),
      });
    }
    */
  }

  Future<void> _initializeRealtimeService() async {
    try {
      await _realtimeService.initialize();

      // Update real-time service with current data
      _realtimeService.updateAllData(
        bookings: _bookings,
        rooms: _rooms,
        guests: _guests,
        payments: _payments,
      );

      // Listen to real-time events
      _eventSubscription = _realtimeService.eventStream.listen(
        _handleRealtimeEvent,
        onError: (error) {
          debugPrint('Real-time event error: $error');
        },
      );

      // Start simulation for demo purposes
      _realtimeService.startSimulation();

      _isInitialized = true;
      debugPrint('Real-time service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing real-time service: $e');
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    debugPrint('Handling real-time event: ${event.type} - ${event.id}');

    switch (event.type) {
      case RealtimeEventType.roomStatusChanged:
        _handleRoomStatusChange(event);
        break;
      case RealtimeEventType.paymentUpdated:
        _handlePaymentUpdate(event);
        break;
      case RealtimeEventType.bookingUpdated:
        _handleBookingUpdate(event);
        break;
      case RealtimeEventType.connectionStatus:
        // Notify listeners about connection status changes
        notifyListeners();
        break;
      case RealtimeEventType.syncComplete:
        debugPrint('Real-time sync completed');
        notifyListeners();
        break;
      case RealtimeEventType.error:
        debugPrint('Real-time error: ${event.data['message']}');
        break;
      default:
        debugPrint('Unhandled real-time event: ${event.type}');
    }
  }

  void _handleRoomStatusChange(RealtimeEvent event) {
    final roomId = event.id;
    final newStatus = event.data['newStatus'] as String;

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex] = Room(
        id: _rooms[roomIndex].id,
        number: _rooms[roomIndex].number,
        type: _rooms[roomIndex].type,
        status: newStatus,
      );
      notifyListeners();
      debugPrint(
        'Room ${event.data['roomNumber']} status changed to $newStatus',
      );
    }
  }

  void _handlePaymentUpdate(RealtimeEvent event) {
    final paymentId = event.id;
    final newStatus = event.data['newStatus'] as String;

    final paymentIndex = _payments.indexWhere((p) => p.id == paymentId);
    if (paymentIndex != -1) {
      _payments[paymentIndex] = Payment(
        id: _payments[paymentIndex].id,
        guest: _payments[paymentIndex].guest,
        amount: _payments[paymentIndex].amount,
        status: newStatus,
        date: _payments[paymentIndex].date,
      );
      notifyListeners();
      debugPrint(
        'Payment for ${event.data['guestName']} updated to $newStatus',
      );
    }
  }

  void _handleBookingUpdate(RealtimeEvent event) {
    final bookingId = event.id;
    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);

    if (bookingIndex != -1) {
      // For demo purposes, just update the notes
      final existingBooking = _bookings[bookingIndex];
      _bookings[bookingIndex] = Booking(
        id: existingBooking.id,
        guest: existingBooking.guest,
        room: existingBooking.room,
        checkIn: existingBooking.checkIn,
        checkOut: existingBooking.checkOut,
        notes: event.data['notes'] as String? ?? existingBooking.notes,
      );
      notifyListeners();
      debugPrint('Booking for ${event.data['guestName']} updated');
    }
  }

  Future<void> _loadSampleData() async {
    debugPrint('🔄 Loading sample data...');

    // Sample Guests (create guests first since other entities depend on them)
    _guests = [
      Guest(
        id: 'guest-1',
        name: 'John Doe',
        email: 'john.doe@email.com',
        phone: '+1-555-0123',
      ),
      Guest(
        id: 'guest-2',
        name: 'Jane Smith',
        email: 'jane.smith@email.com',
        phone: '+1-555-0456',
      ),
    ];

    // Sample Rooms
    _rooms = [
      Room(id: 'room-1', number: '101', type: 'Deluxe', status: 'Available'),
      Room(id: 'room-2', number: '102', type: 'Standard', status: 'Occupied'),
      Room(id: 'room-3', number: '201', type: 'Suite', status: 'Available'),
      Room(id: 'room-4', number: '202', type: 'Standard', status: 'Cleaning'),
      Room(id: 'room-5', number: '301', type: 'Deluxe', status: 'Maintenance'),
    ];

    // Sample Bookings
    _bookings = [
      Booking(
        id: 'booking-1',
        guest: _guests[0],
        room: _rooms[1], // Room 102 (Occupied)
        checkIn: DateTime.now().subtract(const Duration(days: 2)),
        checkOut: DateTime.now().add(const Duration(days: 3)),
        notes: 'Standard booking for 2 guests',
        depositPaid: true,
        paymentStatus: 'Paid',
      ),
      Booking(
        id: 'booking-2',
        guest: _guests[1],
        room: _rooms[0], // Room 101 (Available - future booking)
        checkIn: DateTime.now().add(const Duration(days: 5)),
        checkOut: DateTime.now().add(const Duration(days: 8)),
        notes: 'Future booking for 1 guest',
        depositPaid: false,
        paymentStatus: 'Pending',
      ),
    ];

    // Sample Payments (updated to reflect new room pricing)
    _payments = [
      Payment(
        id: 'payment-1',
        guest: _guests[0],
        amount: 25000.0, // 5 nights × ₹5000 (Standard room)
        status: 'Paid',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Payment(
        id: 'payment-2',
        guest: _guests[1],
        amount: 18000.0, // 3 nights × ₹6000 (Deluxe room)
        status: 'Pending',
        date: DateTime.now().add(const Duration(days: 5)),
      ),
      Payment(
        id: 'payment-3',
        guest: _guests[0],
        amount: 10000.0, // 2 nights × ₹5000 (Standard room)
        status: 'Paid',
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    debugPrint(
      '✅ Sample data loaded: ${_guests.length} guests, ${_rooms.length} rooms, ${_bookings.length} bookings, ${_payments.length} payments',
    );
  }

  // CRUD Operations for Bookings
  Future<void> addBooking(Booking booking) async {
    try {
      _bookings.add(booking);

      // Emit real-time event
      _realtimeService.emitBookingEvent(
        RealtimeEventType.bookingAdded,
        booking.id ?? 'unknown',
        {
          'guestName': booking.guest.name,
          'roomNumber': booking.room.number,
          'checkIn': booking.checkIn.toIso8601String(),
          'checkOut': booking.checkOut.toIso8601String(),
        },
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding booking: $e');
      rethrow;
    }
  }

  Future<void> updateBooking(String id, Booking booking) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == id);
      if (index != -1) {
        _bookings[index] = booking;

        // Emit real-time event
        _realtimeService
            .emitBookingEvent(RealtimeEventType.bookingUpdated, id, {
              'guestName': booking.guest.name,
              'roomNumber': booking.room.number,
              'checkIn': booking.checkIn.toIso8601String(),
              'checkOut': booking.checkOut.toIso8601String(),
            });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating booking: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      final booking = _bookings.where((b) => b.id == id).isNotEmpty
          ? _bookings.where((b) => b.id == id).first
          : null;

      _bookings.removeWhere((b) => b.id == id);

      // Emit real-time event only if booking was found
      if (booking != null) {
        _realtimeService.emitBookingEvent(
          RealtimeEventType.bookingDeleted,
          id,
          {'guestName': booking.guest.name, 'roomNumber': booking.room.number},
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      rethrow;
    }
  }

  // CRUD Operations for Rooms
  Future<void> addRoom(Room room) async {
    try {
      _rooms.add(room);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding room: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(String id, Room room) async {
    try {
      final index = _rooms.indexWhere((r) => r.id == id);
      if (index != -1) {
        _rooms[index] = room;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating room: $e');
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      final room = _rooms.where((r) => r.id == roomId).isNotEmpty
          ? _rooms.where((r) => r.id == roomId).first
          : null;
      if (room == null) {
        debugPrint('Room with ID $roomId not found');
        return;
      }

      final oldStatus = room.status;
      final updatedRoom = Room(
        id: room.id,
        number: room.number,
        type: room.type,
        status: status,
      );
      await updateRoom(roomId, updatedRoom);

      // Emit real-time event
      _realtimeService.emitRoomEvent(
        RealtimeEventType.roomStatusChanged,
        roomId,
        {
          'roomNumber': room.number,
          'oldStatus': oldStatus,
          'newStatus': status,
        },
      );
    } catch (e) {
      debugPrint('Error updating room status: $e');
      rethrow;
    }
  }

  Future<void> updateRoomStatusByNumber(
    String roomNumber,
    String status,
  ) async {
    try {
      final room = _rooms.where((r) => r.number == roomNumber).isNotEmpty
          ? _rooms.where((r) => r.number == roomNumber).first
          : null;
      if (room == null) {
        debugPrint('Room with number $roomNumber not found');
        return;
      }

      final roomId = room.id;
      if (roomId != null && roomId.isNotEmpty) {
        await updateRoomStatus(roomId, status);
      } else {
        debugPrint('Room ID is null or empty for room number $roomNumber');
      }
    } catch (e) {
      debugPrint('Error updating room status by number: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      _rooms.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting room: $e');
      rethrow;
    }
  }

  // CRUD Operations for Guests
  Future<void> addGuest(Guest guest) async {
    try {
      _guests.add(guest);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding guest: $e');
      rethrow;
    }
  }

  Future<void> updateGuest(String id, Guest guest) async {
    try {
      final index = _guests.indexWhere((g) => g.id == id);
      if (index != -1) {
        _guests[index] = guest;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating guest: $e');
      rethrow;
    }
  }

  Future<void> deleteGuest(String id) async {
    try {
      _guests.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting guest: $e');
      rethrow;
    }
  }

  // CRUD Operations for Payments
  Future<void> addPayment(Payment payment) async {
    try {
      _payments.add(payment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(String id, Payment payment) async {
    try {
      final index = _payments.indexWhere((p) => p.id == id);
      if (index != -1) {
        _payments[index] = payment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      _payments.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      rethrow;
    }
  }

  // Helper methods for analytics
  List<Booking> getUpcomingCheckIns() {
    final today = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.checkIn.isAfter(today) ||
              (b.checkIn.year == today.year &&
                  b.checkIn.month == today.month &&
                  b.checkIn.day == today.day),
        )
        .toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
  }

  List<Booking> getUpcomingCheckOuts() {
    final today = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.checkOut.isAfter(today) ||
              (b.checkOut.year == today.year &&
                  b.checkOut.month == today.month &&
                  b.checkOut.day == today.day),
        )
        .toList()
      ..sort((a, b) => a.checkOut.compareTo(b.checkOut));
  }

  List<Payment> getPendingPayments() {
    return _payments.where((p) => p.status.toLowerCase() == 'pending').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Additional methods for compatibility
  List<Booking> get activeBookings {
    final now = DateTime.now();
    return _bookings
        .where((b) => b.checkIn.isBefore(now) && b.checkOut.isAfter(now))
        .toList();
  }

  List<Booking> get todayCheckIns {
    final today = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.checkIn.year == today.year &&
              b.checkIn.month == today.month &&
              b.checkIn.day == today.day,
        )
        .toList();
  }

  List<Payment> get pendingPayments => getPendingPayments();

  // Search and filter methods
  List<Booking> searchBookings(String query) {
    if (query.isEmpty) return _bookings;
    return _bookings.where((booking) {
      return booking.guest.name.toLowerCase().contains(query.toLowerCase()) ||
          booking.room.number.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Room> getAvailableRooms() {
    return _rooms.where((r) => r.status.toLowerCase() == 'available').toList();
  }

  // Real-time updates simulation
  void simulateRealTimeUpdate() {
    // This can be used to simulate real-time updates
    // In a real app, this would be triggered by external events
    notifyListeners();
  }

  // Manual sync with real-time service
  Future<void> manualSync() async {
    if (_isInitialized) {
      await _realtimeService.manualSync();
    }
  }

  // Cleanup and dispose
  @override
  void dispose() {
    _eventSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  /// Check if current data is real (from Firebase) or sample data
  bool get isUsingRealData {
    // Check if we have data that matches real Firebase structure
    // Real data will have proper Firebase document IDs (longer than 10 chars)
    return guests.isNotEmpty &&
        guests.any(
          (g) => g.id != null && g.id!.isNotEmpty && g.id!.length > 10,
        ) &&
        rooms.isNotEmpty &&
        rooms.any((r) => r.id != null && r.id!.isNotEmpty && r.id!.length > 10);
  }

  /// Get data source information
  String get dataSourceInfo {
    if (!isInitialized) return 'Not initialized';
    if (isUsingRealData) {
      return 'Real data from Firebase (${guests.length} guests, ${rooms.length} rooms, ${bookings.length} bookings, ${payments.length} payments)';
    } else {
      return 'Sample data (${guests.length} guests, ${rooms.length} rooms, ${bookings.length} bookings, ${payments.length} payments)';
    }
  }

  /// Force refresh from Firebase
  Future<void> refreshFromFirebase() async {
    try {
      debugPrint('🔄 Force refreshing data from Firebase...');
      await loadDataFromFirebase();
      debugPrint('✅ Data refreshed from Firebase');
    } catch (e) {
      debugPrint('❌ Error refreshing from Firebase: $e');
      rethrow;
    }
  }

  /// Force load sample data (for testing or when Firebase is unavailable)
  Future<void> forceSampleData() async {
    try {
      debugPrint('🔧 Force loading sample data...');
      await _loadSampleData();
      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ Sample data force loaded successfully');
    } catch (e) {
      debugPrint('❌ Error force loading sample data: $e');
      rethrow;
    }
  }
}
