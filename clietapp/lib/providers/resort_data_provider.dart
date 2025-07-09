import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';

class ResortDataProvider with ChangeNotifier {
  // Backend: Supabase Integration - Replace Firebase with Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Booking> _bookings = [];
  List<Room> _rooms = [];
  List<Guest> _guests = [];
  List<Payment> _payments = [];

  // Getters
  List<Booking> get bookings => _bookings;
  List<Room> get rooms => _rooms;
  List<Guest> get guests => _guests;
  List<Payment> get payments => _payments;

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

  double get pendingPayments {
    return pendingRevenue; // Alias for pendingRevenue
  }

  List<Booking> get todayCheckIns {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.checkIn.year == today.year &&
          booking.checkIn.month == today.month &&
          booking.checkIn.day == today.day;
    }).toList();
  }

  List<Booking> get todayCheckOuts {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.checkOut.year == today.year &&
          booking.checkOut.month == today.month &&
          booking.checkOut.day == today.day;
    }).toList();
  }

  List<Booking> get activeBookings {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.checkIn.isBefore(today.add(const Duration(days: 1))) &&
          booking.checkOut.isAfter(today.subtract(const Duration(days: 1)));
    }).toList();
  }

  // Backend: Supabase Integration - Real-time streams for data
  Stream<List<Map<String, dynamic>>> get bookingsStream => _supabase
      .from('bookings')
      .stream(primaryKey: ['id'])
      .order('check_in', ascending: false);

  Stream<List<Map<String, dynamic>>> get roomsStream =>
      _supabase.from('rooms').stream(primaryKey: ['id']).order('number');

  Stream<List<Map<String, dynamic>>> get guestsStream =>
      _supabase.from('guests').stream(primaryKey: ['id']).order('name');

  Stream<List<Map<String, dynamic>>> get paymentsStream => _supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .order('date', ascending: false);

  Future<void> loadData() async {
    // Load from both Hive (offline) and Supabase (online)
    await _loadFromHive();
    await _loadFromSupabase();
    _setupSupabaseListeners();
    notifyListeners();
  }

  // Load data from Hive for offline support
  Future<void> _loadFromHive() async {
    await _loadBookings();
    await _loadRooms();
    await _loadGuests();
    await _loadPayments();
  }

  // Load data from Supabase for online sync
  Future<void> _loadFromSupabase() async {
    try {
      // Load bookings from Supabase
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('*')
          .order('check_in', ascending: false);

      _bookings = (bookingsResponse as List<dynamic>)
          .map((data) => Booking.fromSupabase(data))
          .toList();

      // Load rooms from Supabase
      final roomsResponse = await _supabase
          .from('rooms')
          .select('*')
          .order('number');

      _rooms = (roomsResponse as List<dynamic>)
          .map((data) => Room.fromSupabase(data))
          .toList();

      // Load guests from Supabase
      final guestsResponse = await _supabase
          .from('guests')
          .select('*')
          .order('name');

      _guests = (guestsResponse as List<dynamic>)
          .map((data) => Guest.fromSupabase(data))
          .toList();

      // Load payments from Supabase
      final paymentsResponse = await _supabase
          .from('payments')
          .select('*')
          .order('date', ascending: false);

      _payments = (paymentsResponse as List<dynamic>)
          .map((data) => Payment.fromSupabase(data))
          .toList();

      // If no rooms exist, create default ones
      if (_rooms.isEmpty) {
        await _createDefaultRooms();
      }
    } catch (e) {
      debugPrint('Error loading from Supabase: $e');
      // Fall back to Hive data if Supabase fails (e.g., tables don't exist)
      await _loadBookings();
      await _loadRooms();
      await _loadGuests();
      await _loadPayments();
    }
  }

  // Backend: Supabase Integration - Setup real-time listeners
  void _setupSupabaseListeners() {
    // Listen to bookings changes
    bookingsStream.listen((data) {
      _bookings = data.map((item) => Booking.fromSupabase(item)).toList();
      notifyListeners();
    });

    // Listen to rooms changes
    roomsStream.listen((data) {
      _rooms = data.map((item) => Room.fromSupabase(item)).toList();
      notifyListeners();
    });

    // Listen to guests changes
    guestsStream.listen((data) {
      _guests = data.map((item) => Guest.fromSupabase(item)).toList();
      notifyListeners();
    });

    // Listen to payments changes
    paymentsStream.listen((data) {
      _payments = data.map((item) => Payment.fromSupabase(item)).toList();
      notifyListeners();
    });
  }

  Future<void> _loadBookings() async {
    try {
      final box = await Hive.openBox<Booking>('bookings');
      _bookings = box.values.toList();
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      _bookings = [];
    }
  }

  Future<void> _loadRooms() async {
    try {
      final box = await Hive.openBox<Room>('rooms');
      _rooms = box.values.toList();

      // If no rooms exist, create some default ones
      if (_rooms.isEmpty) {
        await _createDefaultRooms();
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      _rooms = [];
    }
  }

  Future<void> _loadGuests() async {
    try {
      final box = await Hive.openBox<Guest>('guests');
      _guests = box.values.toList();
    } catch (e) {
      debugPrint('Error loading guests: $e');
      _guests = [];
    }
  }

  Future<void> _loadPayments() async {
    try {
      final box = await Hive.openBox<Payment>('payments');
      _payments = box.values.toList();
    } catch (e) {
      debugPrint('Error loading payments: $e');
      _payments = [];
    }
  }

  Future<void> _createDefaultRooms() async {
    final box = await Hive.openBox<Room>('rooms');

    final defaultRooms = [
      Room(number: '101', type: 'Standard', status: 'available'),
      Room(number: '102', type: 'Standard', status: 'available'),
      Room(number: '201', type: 'Deluxe', status: 'occupied'),
      Room(number: '202', type: 'Deluxe', status: 'available'),
      Room(number: '301', type: 'Suite', status: 'cleaning'),
    ];

    for (var room in defaultRooms) {
      await box.add(room);
    }

    _rooms = defaultRooms;
  }

  // CRUD operations for Bookings with Supabase sync
  Future<void> addBooking(Booking booking) async {
    try {
      // Backend: Supabase Integration - Add to Supabase first
      final response = await _supabase
          .from('bookings')
          .insert(booking.toSupabase())
          .select();

      // Add to Hive for offline support
      final box = await Hive.openBox<Booking>('bookings');
      await box.add(booking);
      _bookings.add(booking);

      // Sync: Update room status when booking is added
      await _updateRoomStatusFromBooking(booking, 'occupied');

      // Sync: Add guest if not exists
      await _ensureGuestExists(booking.guest);

      // Sync: Create payment record
      await _createPaymentForBooking(booking);

      notifyListeners(); // Data Flow: Notify all listeners

      debugPrint(
        'Booking added successfully to Supabase: ${response.first['id']}',
      );
    } catch (e) {
      debugPrint('Error adding booking to Supabase: $e');

      // Bug Prevention: Fallback to Hive only if Supabase fails
      final box = await Hive.openBox<Booking>('bookings');
      await box.add(booking);
      _bookings.add(booking);

      notifyListeners();
    }
  }

  Future<void> updateBooking(int index, Booking booking) async {
    final box = await Hive.openBox<Booking>('bookings');
    final oldBooking = _bookings[index];

    await box.putAt(index, booking);
    _bookings[index] = booking;

    // Sync: Update room status if room changed
    if (oldBooking.room.number != booking.room.number) {
      await _updateRoomStatusFromBooking(oldBooking, 'available');
      await _updateRoomStatusFromBooking(booking, 'occupied');
    }

    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> deleteBooking(int index) async {
    final box = await Hive.openBox<Booking>('bookings');
    final booking = _bookings[index];

    await box.deleteAt(index);
    _bookings.removeAt(index);

    // Sync: Update room status to available
    await _updateRoomStatusFromBooking(booking, 'available');

    notifyListeners(); // Data Flow: Notify all listeners
  }

  // Enhanced room status management
  Future<void> updateRoomStatus(String roomNumber, String newStatus) async {
    final roomIndex = _rooms.indexWhere((r) => r.number == roomNumber);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      room.status = newStatus;

      final box = await Hive.openBox<Room>('rooms');
      await box.putAt(roomIndex, room);

      notifyListeners(); // Data Flow: Notify all listeners
    }
  }

  // Helper methods for synchronization
  Future<void> _updateRoomStatusFromBooking(
    Booking booking,
    String status,
  ) async {
    final roomIndex = _rooms.indexWhere((r) => r.number == booking.room.number);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      room.status = status;

      final box = await Hive.openBox<Room>('rooms');
      await box.putAt(roomIndex, room);
    }
  }

  Future<void> _ensureGuestExists(Guest guest) async {
    final exists = _guests.any((g) => g.email == guest.email);
    if (!exists) {
      await addGuest(guest);
    }
  }

  Future<void> _createPaymentForBooking(Booking booking) async {
    // Calculate payment amount (simplified calculation)
    const baseRate = 2500.0; // Default rate
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final amount = baseRate * nights;

    final payment = Payment(
      guest: booking.guest,
      amount: amount,
      status: booking.paymentStatus,
      date: booking.checkIn,
    );

    await addPayment(payment);
  }

  // CRUD operations for Rooms
  Future<void> addRoom(Room room) async {
    final box = await Hive.openBox<Room>('rooms');
    await box.add(room);
    _rooms.add(room);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> updateRoom(int index, Room room) async {
    final box = await Hive.openBox<Room>('rooms');
    await box.putAt(index, room);
    _rooms[index] = room;
    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> deleteRoom(int index) async {
    final box = await Hive.openBox<Room>('rooms');
    await box.deleteAt(index);
    _rooms.removeAt(index);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  // CRUD operations for Guests
  Future<void> addGuest(Guest guest) async {
    final box = await Hive.openBox<Guest>('guests');
    await box.add(guest);
    _guests.add(guest);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> updateGuest(int index, Guest guest) async {
    final box = await Hive.openBox<Guest>('guests');
    await box.putAt(index, guest);
    _guests[index] = guest;

    // Sync: Update guest info in related bookings
    await _updateGuestInBookings(guest);

    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> deleteGuest(int index) async {
    final box = await Hive.openBox<Guest>('guests');
    await box.deleteAt(index);
    _guests.removeAt(index);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  // CRUD operations for Payments
  Future<void> addPayment(Payment payment) async {
    final box = await Hive.openBox<Payment>('payments');
    await box.add(payment);
    _payments.add(payment);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> updatePayment(int index, Payment payment) async {
    final box = await Hive.openBox<Payment>('payments');
    await box.putAt(index, payment);
    _payments[index] = payment;

    // Sync: Update payment status in related bookings
    await _updatePaymentStatusInBookings(payment);

    notifyListeners(); // Data Flow: Notify all listeners
  }

  Future<void> deletePayment(int index) async {
    final box = await Hive.openBox<Payment>('payments');
    await box.deleteAt(index);
    _payments.removeAt(index);
    notifyListeners(); // Data Flow: Notify all listeners
  }

  // Enhanced synchronization methods
  Future<void> _updateGuestInBookings(Guest guest) async {
    final box = await Hive.openBox<Booking>('bookings');
    for (int i = 0; i < _bookings.length; i++) {
      if (_bookings[i].guest.email == guest.email) {
        _bookings[i].guest = guest;
        await box.putAt(i, _bookings[i]);
      }
    }
  }

  Future<void> _updatePaymentStatusInBookings(Payment payment) async {
    final box = await Hive.openBox<Booking>('bookings');
    for (int i = 0; i < _bookings.length; i++) {
      if (_bookings[i].guest.email == payment.guest.email) {
        _bookings[i].paymentStatus = payment.status;
        await box.putAt(i, _bookings[i]);
      }
    }
  }

  // Real-time analytics updates
  Map<String, dynamic> getAnalyticsData() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    final thisMonthBookings = _bookings
        .where((b) => b.checkIn.isAfter(thisMonth))
        .length;
    final lastMonthBookings = _bookings
        .where(
          (b) => b.checkIn.isAfter(lastMonth) && b.checkIn.isBefore(thisMonth),
        )
        .length;

    final thisMonthRevenue = _payments
        .where(
          (p) => p.date.isAfter(thisMonth) && p.status.toLowerCase() == 'paid',
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    return {
      'occupancyRate': occupancyRate,
      'totalRevenue': totalRevenue,
      'pendingRevenue': pendingRevenue,
      'thisMonthBookings': thisMonthBookings,
      'lastMonthBookings': lastMonthBookings,
      'thisMonthRevenue': thisMonthRevenue,
      'totalRooms': totalRooms,
      'availableRooms': availableRooms,
      'occupiedRooms': occupiedRooms,
      'cleaningRooms': cleaningRooms,
      'maintenanceRooms': maintenanceRooms,
      'todayCheckIns': todayCheckIns.length,
      'todayCheckOuts': todayCheckOuts.length,
      'activeBookings': activeBookings.length,
    };
  }

  // Calendar integration methods
  List<Booking> getBookingsForDate(DateTime date) {
    return _bookings.where((booking) {
      return (booking.checkIn.isBefore(date.add(const Duration(days: 1))) &&
          booking.checkOut.isAfter(date));
    }).toList();
  }

  List<Booking> getBookingsForDateRange(DateTime start, DateTime end) {
    return _bookings.where((booking) {
      return (booking.checkIn.isBefore(end) && booking.checkOut.isAfter(start));
    }).toList();
  }
}
