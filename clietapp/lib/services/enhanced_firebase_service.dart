import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/payment.dart';

/// Enhanced Firebase service with real-time synchronization
/// Provides comprehensive CRUD operations and real-time updates across all pages
class EnhancedFirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _isInitialized = false;

  // Collection references
  static const String BOOKINGS_COLLECTION = 'bookings';
  static const String GUESTS_COLLECTION = 'guests';
  static const String ROOMS_COLLECTION = 'rooms';
  static const String PAYMENTS_COLLECTION = 'payments';
  static const String INVOICES_COLLECTION = 'invoices';
  static const String ANALYTICS_COLLECTION = 'analytics';

  // Stream controllers for real-time updates
  static final StreamController<List<Booking>> _bookingsController =
      StreamController<List<Booking>>.broadcast();
  static final StreamController<List<Guest>> _guestsController =
      StreamController<List<Guest>>.broadcast();
  static final StreamController<List<Room>> _roomsController =
      StreamController<List<Room>>.broadcast();
  static final StreamController<List<Payment>> _paymentsController =
      StreamController<List<Payment>>.broadcast();

  // Stream subscriptions for listening to Firebase changes
  static StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  static StreamSubscription<QuerySnapshot>? _guestsSubscription;
  static StreamSubscription<QuerySnapshot>? _roomsSubscription;
  static StreamSubscription<QuerySnapshot>? _paymentsSubscription;

  // Getters for real-time streams
  static Stream<List<Booking>> get bookingsStream => _bookingsController.stream;
  static Stream<List<Guest>> get guestsStream => _guestsController.stream;
  static Stream<List<Room>> get roomsStream => _roomsController.stream;
  static Stream<List<Payment>> get paymentsStream => _paymentsController.stream;

  static bool get isInitialized => _isInitialized;
  static FirebaseFirestore? get firestore => _firestore;

  /// Initialize Firebase and set up real-time listeners
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence for better user experience
      if (kIsWeb) {
        await _firestore!.enablePersistence();
      } else {
        // For desktop/mobile platforms, use settings
        _firestore!.settings = const Settings(persistenceEnabled: true);
      }

      _isInitialized = true;

      // Set up real-time listeners
      await _setupRealtimeListeners();

      debugPrint('✅ Enhanced Firebase Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Enhanced Firebase Service initialization failed: $e');
      rethrow;
    }
  }

  /// Set up real-time listeners for all collections
  static Future<void> _setupRealtimeListeners() async {
    if (_firestore == null) return;

    try {
      // Bookings real-time listener
      _bookingsSubscription = _firestore!
          .collection(BOOKINGS_COLLECTION)
          .orderBy('checkIn', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              final bookings = snapshot.docs.map((doc) {
                final data = doc.data();
                return Booking.fromMap({...data, 'id': doc.id});
              }).toList();
              _bookingsController.add(bookings);
              debugPrint('🔄 Bookings updated: ${bookings.length} items');
            },
            onError: (error) {
              debugPrint('❌ Bookings stream error: $error');
            },
          );

      // Guests real-time listener
      _guestsSubscription = _firestore!
          .collection(GUESTS_COLLECTION)
          .orderBy('name', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              final guests = snapshot.docs.map((doc) {
                final data = doc.data();
                return Guest.fromMap({...data, 'id': doc.id});
              }).toList();
              _guestsController.add(guests);
              debugPrint('🔄 Guests updated: ${guests.length} items');
            },
            onError: (error) {
              debugPrint('❌ Guests stream error: $error');
            },
          );

      // Rooms real-time listener
      _roomsSubscription = _firestore!
          .collection(ROOMS_COLLECTION)
          .orderBy('number', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              final rooms = snapshot.docs.map((doc) {
                final data = doc.data();
                return Room.fromMap({...data, 'id': doc.id});
              }).toList();
              _roomsController.add(rooms);
              debugPrint('🔄 Rooms updated: ${rooms.length} items');
            },
            onError: (error) {
              debugPrint('❌ Rooms stream error: $error');
            },
          );

      // Payments real-time listener
      _paymentsSubscription = _firestore!
          .collection(PAYMENTS_COLLECTION)
          .orderBy('date', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final payments = snapshot.docs.map((doc) {
                final data = doc.data();
                return Payment.fromMap({...data, 'id': doc.id});
              }).toList();
              _paymentsController.add(payments);
              debugPrint('🔄 Payments updated: ${payments.length} items');
            },
            onError: (error) {
              debugPrint('❌ Payments stream error: $error');
            },
          );

      debugPrint('✅ All real-time listeners set up successfully');
    } catch (e) {
      debugPrint('❌ Error setting up real-time listeners: $e');
    }
  }

  // ===== BOOKING CRUD OPERATIONS =====

  /// Add a new booking with real-time propagation
  static Future<String> addBooking(Booking booking) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final docRef = await _firestore!.collection(BOOKINGS_COLLECTION).add({
        'guestId': booking.guest.id,
        'guestName': booking.guest.name,
        'guestEmail': booking.guest.email,
        'guestPhone': booking.guest.phone,
        'roomId': booking.room.id,
        'roomNumber': booking.room.number,
        'roomType': booking.room.type,
        'checkIn': booking.checkIn.toIso8601String(),
        'checkOut': booking.checkOut.toIso8601String(),
        'notes': booking.notes ?? '',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update room status to occupied/booked
      await updateRoomStatus(booking.room.id!, 'Occupied');

      // Create corresponding payment record
      await addPayment(
        Payment(
          id: null,
          guest: booking.guest,
          amount: _calculateBookingAmount(booking),
          status: 'Pending',
          date: DateTime.now(),
        ),
      );

      debugPrint('✅ Booking added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding booking: $e');
      rethrow;
    }
  }

  /// Update an existing booking
  static Future<void> updateBooking(String bookingId, Booking booking) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      await _firestore!.collection(BOOKINGS_COLLECTION).doc(bookingId).update({
        'guestId': booking.guest.id,
        'guestName': booking.guest.name,
        'guestEmail': booking.guest.email,
        'guestPhone': booking.guest.phone,
        'roomId': booking.room.id,
        'roomNumber': booking.room.number,
        'roomType': booking.room.type,
        'checkIn': booking.checkIn.toIso8601String(),
        'checkOut': booking.checkOut.toIso8601String(),
        'notes': booking.notes ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Booking updated successfully: $bookingId');
    } catch (e) {
      debugPrint('❌ Error updating booking: $e');
      rethrow;
    }
  }

  /// Delete a booking and update related data
  static Future<void> deleteBooking(String bookingId) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      // Get booking data first
      final bookingDoc = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        final data = bookingDoc.data()!;
        final roomId = data['roomId'] as String;

        // Update room status to available
        await updateRoomStatus(roomId, 'Available');

        // Delete related payments
        final paymentsQuery = await _firestore!
            .collection(PAYMENTS_COLLECTION)
            .where('guestId', isEqualTo: data['guestId'])
            .get();

        for (final paymentDoc in paymentsQuery.docs) {
          await paymentDoc.reference.delete();
        }
      }

      // Delete the booking
      await _firestore!.collection(BOOKINGS_COLLECTION).doc(bookingId).delete();

      debugPrint('✅ Booking deleted successfully: $bookingId');
    } catch (e) {
      debugPrint('❌ Error deleting booking: $e');
      rethrow;
    }
  }

  // ===== GUEST CRUD OPERATIONS =====

  /// Add a new guest
  static Future<String> addGuest(Guest guest) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final docRef = await _firestore!.collection(GUESTS_COLLECTION).add({
        'name': guest.name,
        'email': guest.email,
        'phone': guest.phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Guest added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding guest: $e');
      rethrow;
    }
  }

  /// Update an existing guest
  static Future<void> updateGuest(String guestId, Guest guest) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      await _firestore!.collection(GUESTS_COLLECTION).doc(guestId).update({
        'name': guest.name,
        'email': guest.email,
        'phone': guest.phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update all related bookings
      final bookingsQuery = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .where('guestId', isEqualTo: guestId)
          .get();

      for (final bookingDoc in bookingsQuery.docs) {
        await bookingDoc.reference.update({
          'guestName': guest.name,
          'guestEmail': guest.email,
          'guestPhone': guest.phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Guest updated successfully: $guestId');
    } catch (e) {
      debugPrint('❌ Error updating guest: $e');
      rethrow;
    }
  }

  /// Delete a guest and handle related bookings
  static Future<void> deleteGuest(String guestId) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      // Check for active bookings
      final bookingsQuery = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .where('guestId', isEqualTo: guestId)
          .get();

      if (bookingsQuery.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete guest with active bookings. Please cancel bookings first.',
        );
      }

      // Delete related payments
      final paymentsQuery = await _firestore!
          .collection(PAYMENTS_COLLECTION)
          .where('guestId', isEqualTo: guestId)
          .get();

      for (final paymentDoc in paymentsQuery.docs) {
        await paymentDoc.reference.delete();
      }

      // Delete the guest
      await _firestore!.collection(GUESTS_COLLECTION).doc(guestId).delete();

      debugPrint('✅ Guest deleted successfully: $guestId');
    } catch (e) {
      debugPrint('❌ Error deleting guest: $e');
      rethrow;
    }
  }

  // ===== ROOM CRUD OPERATIONS =====

  /// Add a new room
  static Future<String> addRoom(Room room) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final docRef = await _firestore!.collection(ROOMS_COLLECTION).add({
        'number': room.number,
        'type': room.type,
        'status': room.status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Room added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding room: $e');
      rethrow;
    }
  }

  /// Update an existing room
  static Future<void> updateRoom(String roomId, Room room) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      await _firestore!.collection(ROOMS_COLLECTION).doc(roomId).update({
        'number': room.number,
        'type': room.type,
        'status': room.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update all related bookings
      final bookingsQuery = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .where('roomId', isEqualTo: roomId)
          .get();

      for (final bookingDoc in bookingsQuery.docs) {
        await bookingDoc.reference.update({
          'roomNumber': room.number,
          'roomType': room.type,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Room updated successfully: $roomId');
    } catch (e) {
      debugPrint('❌ Error updating room: $e');
      rethrow;
    }
  }

  /// Update room status only
  static Future<void> updateRoomStatus(String roomId, String status) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      await _firestore!.collection(ROOMS_COLLECTION).doc(roomId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Room status updated: $roomId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating room status: $e');
      rethrow;
    }
  }

  /// Delete a room
  static Future<void> deleteRoom(String roomId) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      // Check for active bookings
      final bookingsQuery = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .where('roomId', isEqualTo: roomId)
          .get();

      if (bookingsQuery.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete room with active bookings. Please cancel bookings first.',
        );
      }

      // Delete the room
      await _firestore!.collection(ROOMS_COLLECTION).doc(roomId).delete();

      debugPrint('✅ Room deleted successfully: $roomId');
    } catch (e) {
      debugPrint('❌ Error deleting room: $e');
      rethrow;
    }
  }

  // ===== PAYMENT CRUD OPERATIONS =====

  /// Add a new payment
  static Future<String> addPayment(Payment payment) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final docRef = await _firestore!.collection(PAYMENTS_COLLECTION).add({
        'guestId': payment.guest.id,
        'guestName': payment.guest.name,
        'amount': payment.amount,
        'status': payment.status,
        'date': payment.date.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Payment added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding payment: $e');
      rethrow;
    }
  }

  /// Update payment status
  static Future<void> updatePaymentStatus(
    String paymentId,
    String status,
  ) async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      await _firestore!.collection(PAYMENTS_COLLECTION).doc(paymentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Payment status updated: $paymentId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      rethrow;
    }
  }

  // ===== ANALYTICS AND QUERIES =====

  /// Get collection counts for analytics
  static Future<Map<String, int>> getCollectionCounts() async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final futures = await Future.wait([
        _firestore!.collection(BOOKINGS_COLLECTION).count().get(),
        _firestore!.collection(GUESTS_COLLECTION).count().get(),
        _firestore!.collection(ROOMS_COLLECTION).count().get(),
        _firestore!.collection(PAYMENTS_COLLECTION).count().get(),
      ]);

      return {
        'bookings': futures[0].count ?? 0,
        'guests': futures[1].count ?? 0,
        'rooms': futures[2].count ?? 0,
        'payments': futures[3].count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting collection counts: $e');
      return {'bookings': 0, 'guests': 0, 'rooms': 0, 'payments': 0};
    }
  }

  /// Get available rooms
  static Future<List<Room>> getAvailableRooms() async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final snapshot = await _firestore!
          .collection(ROOMS_COLLECTION)
          .where('status', isEqualTo: 'Available')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Room.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting available rooms: $e');
      return [];
    }
  }

  /// Get revenue analytics
  static Future<Map<String, dynamic>> getRevenueAnalytics() async {
    if (_firestore == null) throw Exception('Firebase not initialized');

    try {
      final paymentsSnapshot = await _firestore!
          .collection(PAYMENTS_COLLECTION)
          .get();

      double totalRevenue = 0;
      double pendingRevenue = 0;
      double overdueRevenue = 0;

      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String? ?? '';

        switch (status.toLowerCase()) {
          case 'paid':
            totalRevenue += amount;
            break;
          case 'pending':
            pendingRevenue += amount;
            break;
          case 'overdue':
            overdueRevenue += amount;
            break;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingRevenue': pendingRevenue,
        'overdueRevenue': overdueRevenue,
        'totalTransactions': paymentsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting revenue analytics: $e');
      return {
        'totalRevenue': 0.0,
        'pendingRevenue': 0.0,
        'overdueRevenue': 0.0,
        'totalTransactions': 0,
      };
    }
  }

  // ===== UTILITY METHODS =====

  /// Calculate booking amount based on room type and duration
  static double _calculateBookingAmount(Booking booking) {
    final duration = booking.checkOut.difference(booking.checkIn).inDays;
    double baseRate;

    switch (booking.room.type.toLowerCase()) {
      case 'suite':
        baseRate = 7000.0; // ₹7000 per night
        break;
      case 'deluxe':
        baseRate = 6000.0; // ₹6000 per night
        break;
      case 'standard':
        baseRate = 5000.0; // ₹5000 per night
        break;
      default:
        baseRate = 5000.0; // Default to Standard rate
    }

    return baseRate * duration;
  }

  /// Initialize sample data for testing
  static Future<void> initializeSampleData() async {
    try {
      // Check if data already exists
      final bookingsCount = await _firestore!
          .collection(BOOKINGS_COLLECTION)
          .count()
          .get();
      if ((bookingsCount.count ?? 0) > 0) {
        debugPrint('Sample data already exists, skipping initialization');
        return;
      }

      // Add sample guests
      await addGuest(
        Guest(
          id: null,
          name: 'John Doe',
          email: 'john.doe@email.com',
          phone: '+1-555-0123',
        ),
      );

      await addGuest(
        Guest(
          id: null,
          name: 'Jane Smith',
          email: 'jane.smith@email.com',
          phone: '+1-555-0456',
        ),
      );

      // Add sample rooms
      await addRoom(
        Room(id: null, number: '101', type: 'Deluxe', status: 'Available'),
      );

      await addRoom(
        Room(id: null, number: '102', type: 'Standard', status: 'Available'),
      );

      await addRoom(
        Room(id: null, number: '201', type: 'Suite', status: 'Available'),
      );

      // Wait a moment for the data to propagate
      await Future.delayed(const Duration(seconds: 1));

      debugPrint('✅ Sample data initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing sample data: $e');
    }
  }

  /// Dispose all resources
  static Future<void> dispose() async {
    await _bookingsSubscription?.cancel();
    await _guestsSubscription?.cancel();
    await _roomsSubscription?.cancel();
    await _paymentsSubscription?.cancel();

    await _bookingsController.close();
    await _guestsController.close();
    await _roomsController.close();
    await _paymentsController.close();

    _isInitialized = false;
    debugPrint('✅ Enhanced Firebase Service disposed');
  }
}
