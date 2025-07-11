import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import '../utils/supabase_service.dart';

class ResortDataProvider with ChangeNotifier {
  // Backend: Supabase Integration
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
    // Load data from Supabase
    await _loadFromSupabase();
    _setupSupabaseListeners();
    notifyListeners();
  }

  // Load data from Supabase
  Future<void> _loadFromSupabase() async {
    try {
      // Load bookings from Supabase
      _bookings = await SupabaseService.getBookings();

      // Load rooms from Supabase
      _rooms = await SupabaseService.getRooms();

      // Load guests from Supabase
      _guests = await SupabaseService.getGuests();

      // Load payments from Supabase
      _payments = await SupabaseService.getPayments();
    } catch (e) {
      debugPrint('Error loading data from Supabase: $e');
    }
  }

  // Setup real-time listeners for Supabase data changes
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

  // Booking operations
  Future<void> addBooking(Booking booking) async {
    try {
      await SupabaseService.addBooking(booking);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding booking: $e');
      rethrow;
    }
  }

  Future<void> updateBooking(String id, Booking booking) async {
    try {
      await SupabaseService.updateBooking(id, booking);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booking: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      await SupabaseService.deleteBooking(id);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      rethrow;
    }
  }

  // Room operations
  Future<void> addRoom(Room room) async {
    try {
      await SupabaseService.addRoom(room);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding room: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(String id, Room room) async {
    try {
      await SupabaseService.updateRoom(id, room);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating room: $e');
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomNumber, String status) async {
    try {
      final room = _rooms.firstWhere((r) => r.number == roomNumber);
      room.status = status;
      if (room.id != null) {
        await SupabaseService.updateRoom(room.id!, room);
        await _loadFromSupabase();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating room status: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await SupabaseService.deleteRoom(id);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting room: $e');
      rethrow;
    }
  }

  // Guest operations
  Future<void> addGuest(Guest guest) async {
    try {
      await SupabaseService.addGuest(guest);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding guest: $e');
      rethrow;
    }
  }

  Future<void> updateGuest(String id, Guest guest) async {
    try {
      await SupabaseService.updateGuest(id, guest);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating guest: $e');
      rethrow;
    }
  }

  Future<void> deleteGuest(String id) async {
    try {
      await SupabaseService.deleteGuest(id);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting guest: $e');
      rethrow;
    }
  }

  // Payment operations
  Future<void> addPayment(Payment payment) async {
    try {
      await SupabaseService.addPayment(payment);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> updatePayment(String id, Payment payment) async {
    try {
      await SupabaseService.updatePayment(id, payment);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await SupabaseService.deletePayment(id);
      await _loadFromSupabase();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      rethrow;
    }
  }

  // Utility methods
  Room? getRoomByNumber(String number) {
    try {
      return _rooms.firstWhere((room) => room.number == number);
    } catch (e) {
      return null;
    }
  }

  Guest? getGuestByEmail(String email) {
    try {
      return _guests.firstWhere((guest) => guest.email == email);
    } catch (e) {
      return null;
    }
  }

  List<Booking> getBookingsForRoom(String roomNumber) {
    return _bookings
        .where((booking) => booking.room.number == roomNumber)
        .toList();
  }

  List<Payment> getPaymentsForGuest(String guestName) {
    return _payments
        .where((payment) => payment.guest.name == guestName)
        .toList();
  }

  // Initialize sample data if database is empty
  Future<void> initializeSampleData() async {
    try {
      if (_rooms.isEmpty) {
        // Add sample rooms
        final sampleRooms = [
          Room(number: '101', type: 'Standard', status: 'available'),
          Room(number: '102', type: 'Standard', status: 'occupied'),
          Room(number: '201', type: 'Suite', status: 'available'),
          Room(number: '202', type: 'Suite', status: 'cleaning'),
        ];

        for (final room in sampleRooms) {
          await addRoom(room);
        }
      }

      if (_guests.isEmpty) {
        // Add sample guests
        final sampleGuests = [
          Guest(
            name: 'John Doe',
            email: 'john@example.com',
            phone: '+1234567890',
          ),
          Guest(
            name: 'Jane Smith',
            email: 'jane@example.com',
            phone: '+0987654321',
          ),
        ];

        for (final guest in sampleGuests) {
          await addGuest(guest);
        }
      }
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }
}
