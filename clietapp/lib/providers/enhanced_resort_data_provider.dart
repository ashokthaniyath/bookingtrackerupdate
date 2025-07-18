import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';
import '../services/enhanced_firebase_service_stub.dart';
import 'resort_data_provider.dart';

/// Enhanced Real-time Data Provider
/// Manages real-time synchronization across all pages using Firebase
class EnhancedResortDataProvider extends ResortDataProvider {
  // Stream subscriptions
  StreamSubscription<List<Booking>>? _bookingsSubscription;
  StreamSubscription<List<Room>>? _roomsSubscription;
  StreamSubscription<List<Guest>>? _guestsSubscription;
  StreamSubscription<List<Payment>>? _paymentsSubscription;

  bool _enhancedInitialized = false;
  bool _isLoading = false;

  // Override getters to use parent's data
  @override
  bool get isInitialized => _enhancedInitialized && super.isInitialized;
  bool get isLoading => _isLoading;

  // Override analytics methods to use parent's data
  @override
  double get totalRevenue {
    return payments
        .where((p) => p.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  @override
  double get pendingRevenue {
    return payments
        .where((p) => p.status.toLowerCase() == 'pending')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  @override
  double get totalOutstanding {
    return payments
        .where((p) => p.status.toLowerCase() == 'overdue')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  @override
  Map<String, double> get roomStatusData {
    return {
      'Available': availableRooms.toDouble(),
      'Occupied': occupiedRooms.toDouble(),
      'Cleaning': cleaningRooms.toDouble(),
      'Maintenance': maintenanceRooms.toDouble(),
    };
  }

  @override
  List<Map<String, dynamic>> get revenueData {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - index, 1);
      return month;
    }).reversed.toList();

    return months.map((month) {
      final monthPayments = payments.where(
        (p) =>
            p.date.year == month.year &&
            p.date.month == month.month &&
            p.status.toLowerCase() == 'paid',
      );
      final revenue = monthPayments.fold(0.0, (sum, p) => sum + p.amount);
      return {'month': '${month.month}/${month.year}', 'revenue': revenue};
    }).toList();
  }

  /// Initialize the provider with real-time Firebase streams and real data
  Future<void> initialize() async {
    if (_enhancedInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Ensure Firebase is initialized
      if (!EnhancedFirebaseService.isInitialized) {
        await EnhancedFirebaseService.initialize();
      }

      // Load real data first from parent provider
      await super.loadDataFromFirebase();

      // Set up real-time listeners for live updates
      _setupFirebaseStreams();

      _enhancedInitialized = true;
      debugPrint('✅ Enhanced Resort Data Provider initialized with real data');
    } catch (e) {
      debugPrint('❌ Error initializing Enhanced Resort Data Provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up Firebase real-time streams
  void _setupFirebaseStreams() {
    // Listen to bookings changes
    _bookingsSubscription = EnhancedFirebaseService.bookingsStream.listen(
      (bookingsList) {
        // Update parent's bookings using setter
        bookings = bookingsList;
        notifyListeners();
        debugPrint('🔄 Bookings updated: ${bookingsList.length} items');
      },
      onError: (error) {
        debugPrint('❌ Bookings stream error: $error');
      },
    );

    // Listen to rooms changes
    _roomsSubscription = EnhancedFirebaseService.roomsStream.listen(
      (roomsList) {
        // Update parent's rooms using setter
        rooms = roomsList;
        notifyListeners();
        debugPrint('🔄 Rooms updated: ${roomsList.length} items');
      },
      onError: (error) {
        debugPrint('❌ Rooms stream error: $error');
      },
    );

    // Listen to guests changes
    _guestsSubscription = EnhancedFirebaseService.guestsStream.listen(
      (guestsList) {
        // Update parent's guests using setter
        guests = guestsList;
        notifyListeners();
        debugPrint('🔄 Guests updated: ${guestsList.length} items');
      },
      onError: (error) {
        debugPrint('❌ Guests stream error: $error');
      },
    );

    // Listen to payments changes
    _paymentsSubscription = EnhancedFirebaseService.paymentsStream.listen(
      (paymentsList) {
        // Update parent's payments using setter
        payments = paymentsList;
        notifyListeners();
        debugPrint('🔄 Payments updated: ${paymentsList.length} items');
      },
      onError: (error) {
        debugPrint('❌ Payments stream error: $error');
      },
    );
  }

  // ===== BOOKING OPERATIONS =====

  /// Add a new booking
  @override
  Future<String> addBooking(Booking booking) async {
    try {
      final bookingId = await EnhancedFirebaseService.addBooking(booking);
      debugPrint('✅ Booking added via provider: $bookingId');
      return bookingId;
    } catch (e) {
      debugPrint('❌ Error adding booking via provider: $e');
      rethrow;
    }
  }

  /// Update an existing booking
  @override
  Future<void> updateBooking(String bookingId, Booking booking) async {
    try {
      await EnhancedFirebaseService.updateBooking(bookingId, booking);
      debugPrint('✅ Booking updated via provider: $bookingId');
    } catch (e) {
      debugPrint('❌ Error updating booking via provider: $e');
      rethrow;
    }
  }

  /// Delete a booking
  @override
  Future<void> deleteBooking(String bookingId) async {
    try {
      await EnhancedFirebaseService.deleteBooking(bookingId);
      debugPrint('✅ Booking deleted via provider: $bookingId');
    } catch (e) {
      debugPrint('❌ Error deleting booking via provider: $e');
      rethrow;
    }
  }

  // ===== GUEST OPERATIONS =====

  /// Add a new guest
  @override
  Future<String> addGuest(Guest guest) async {
    try {
      final guestId = await EnhancedFirebaseService.addGuest(guest);
      debugPrint('✅ Guest added via provider: $guestId');
      return guestId;
    } catch (e) {
      debugPrint('❌ Error adding guest via provider: $e');
      rethrow;
    }
  }

  /// Update an existing guest
  @override
  Future<void> updateGuest(String guestId, Guest guest) async {
    try {
      await EnhancedFirebaseService.updateGuest(guestId, guest);
      debugPrint('✅ Guest updated via provider: $guestId');
    } catch (e) {
      debugPrint('❌ Error updating guest via provider: $e');
      rethrow;
    }
  }

  /// Delete a guest
  @override
  Future<void> deleteGuest(String guestId) async {
    try {
      await EnhancedFirebaseService.deleteGuest(guestId);
      debugPrint('✅ Guest deleted via provider: $guestId');
    } catch (e) {
      debugPrint('❌ Error deleting guest via provider: $e');
      rethrow;
    }
  }

  // ===== ROOM OPERATIONS =====

  /// Add a new room
  @override
  Future<String> addRoom(Room room) async {
    try {
      final roomId = await EnhancedFirebaseService.addRoom(room);
      debugPrint('✅ Room added via provider: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('❌ Error adding room via provider: $e');
      rethrow;
    }
  }

  /// Update an existing room
  @override
  Future<void> updateRoom(String roomId, Room room) async {
    try {
      await EnhancedFirebaseService.updateRoom(roomId, room);
      debugPrint('✅ Room updated via provider: $roomId');
    } catch (e) {
      debugPrint('❌ Error updating room via provider: $e');
      rethrow;
    }
  }

  /// Update room status
  @override
  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await EnhancedFirebaseService.updateRoomStatus(roomId, status);
      debugPrint('✅ Room status updated via provider: $roomId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating room status via provider: $e');
      rethrow;
    }
  }

  /// Delete a room
  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await EnhancedFirebaseService.deleteRoom(roomId);
      debugPrint('✅ Room deleted via provider: $roomId');
    } catch (e) {
      debugPrint('❌ Error deleting room via provider: $e');
      rethrow;
    }
  }

  // ===== PAYMENT OPERATIONS =====

  /// Add a new payment
  @override
  Future<String> addPayment(Payment payment) async {
    try {
      final paymentId = await EnhancedFirebaseService.addPayment(payment);
      debugPrint('✅ Payment added via provider: $paymentId');
      return paymentId;
    } catch (e) {
      debugPrint('❌ Error adding payment via provider: $e');
      rethrow;
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await EnhancedFirebaseService.updatePaymentStatus(paymentId, status);
      debugPrint(
        '✅ Payment status updated via provider: $paymentId -> $status',
      );
    } catch (e) {
      debugPrint('❌ Error updating payment status via provider: $e');
      rethrow;
    }
  }

  // ===== QUERY METHODS =====

  /// Get available rooms
  @override
  List<Room> getAvailableRooms() {
    return rooms.where((r) => r.status.toLowerCase() == 'available').toList();
  }

  /// Get upcoming check-ins
  @override
  List<Booking> getUpcomingCheckIns() {
    final today = DateTime.now();
    return bookings
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

  /// Get upcoming check-outs
  @override
  List<Booking> getUpcomingCheckOuts() {
    final today = DateTime.now();
    return bookings
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

  /// Get pending payments
  @override
  List<Payment> getPendingPayments() {
    return payments.where((p) => p.status.toLowerCase() == 'pending').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get active bookings
  @override
  List<Booking> get activeBookings {
    final now = DateTime.now();
    return bookings
        .where((b) => b.checkIn.isBefore(now) && b.checkOut.isAfter(now))
        .toList();
  }

  /// Get today's check-ins
  @override
  List<Booking> get todayCheckIns {
    final today = DateTime.now();
    return bookings
        .where(
          (b) =>
              b.checkIn.year == today.year &&
              b.checkIn.month == today.month &&
              b.checkIn.day == today.day,
        )
        .toList();
  }

  /// Search bookings
  @override
  List<Booking> searchBookings(String query) {
    if (query.isEmpty) return bookings;
    return bookings.where((booking) {
      return booking.guest.name.toLowerCase().contains(query.toLowerCase()) ||
          booking.room.number.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get analytics data
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      final revenueData = await EnhancedFirebaseService.getRevenueAnalytics();
      final collectionCounts =
          await EnhancedFirebaseService.getCollectionCounts();

      return {
        ...revenueData,
        ...collectionCounts,
        'occupancyRate': occupancyRate,
        'roomStatusData': roomStatusData,
        'revenueData': this.revenueData,
      };
    } catch (e) {
      debugPrint('❌ Error getting analytics data: $e');
      return {};
    }
  }

  /// Manual refresh
  Future<void> refresh() async {
    try {
      // Firebase streams will automatically update the data
      // This method can be used to trigger analytics refresh
      notifyListeners();
      debugPrint('✅ Data refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _roomsSubscription?.cancel();
    _guestsSubscription?.cancel();
    _paymentsSubscription?.cancel();
    super.dispose();
  }
}
