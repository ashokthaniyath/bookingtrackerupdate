import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/payment.dart';

class FirestoreService {
  static FirebaseFirestore? _firestore;

  // Collection IDs for Cloud Firestore
  static const String BOOKINGS_COLLECTION = 'bookings';
  static const String GUESTS_COLLECTION = 'guests';
  static const String ROOMS_COLLECTION = 'rooms';
  static const String PAYMENTS_COLLECTION = 'payments';
  static const String USERS_COLLECTION = 'users';
  static const String SETTINGS_COLLECTION = 'settings';
  static const String ANALYTICS_COLLECTION = 'analytics';

  /// Initialize Firebase and Firestore
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      print('✅ Firestore initialized successfully');

      // Enable offline persistence
      await _firestore!.enablePersistence();
      print('✅ Firestore offline persistence enabled');
    } catch (e) {
      print('❌ Firestore initialization failed: $e');
    }
  }

  /// Get Firestore instance
  static FirebaseFirestore get instance {
    if (_firestore == null) {
      throw Exception(
        'Firestore not initialized. Call FirestoreService.initialize() first.',
      );
    }
    return _firestore!;
  }

  /// Check if Firestore is initialized
  static bool get isInitialized => _firestore != null;

  // ==================== BOOKING OPERATIONS ====================

  /// Add a new booking to Firestore
  static Future<String> addBooking(Booking booking) async {
    try {
      final docRef = await instance.collection(BOOKINGS_COLLECTION).add({
        'guestName': booking.guest.name,
        'guestEmail': booking.guest.email,
        'guestPhone': booking.guest.phone,
        'roomNumber': booking.room.number,
        'roomType': booking.room.type,
        'roomStatus': booking.room.status,
        'checkIn': booking.checkIn.toIso8601String(),
        'checkOut': booking.checkOut.toIso8601String(),
        'notes': booking.notes,
        'depositPaid': booking.depositPaid,
        'paymentStatus': booking.paymentStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Booking added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding booking: $e');
      rethrow;
    }
  }

  /// Get all bookings from Firestore
  static Future<List<Booking>> getBookings() async {
    try {
      final querySnapshot = await instance
          .collection(BOOKINGS_COLLECTION)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromSupabase({
          'id': doc.id,
          'guest_name': data['guestName'] ?? '',
          'guest_email': data['guestEmail'],
          'guest_phone': data['guestPhone'],
          'room_number': data['roomNumber'] ?? '',
          'room_type': data['roomType'] ?? '',
          'room_status': data['roomStatus'] ?? '',
          'check_in': data['checkIn'] ?? '',
          'check_out': data['checkOut'] ?? '',
          'notes': data['notes'] ?? '',
          'deposit_paid': data['depositPaid'] ?? false,
          'payment_status': data['paymentStatus'] ?? 'Pending',
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting bookings: $e');
      return [];
    }
  }

  /// Update booking in Firestore
  static Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await instance
          .collection(BOOKINGS_COLLECTION)
          .doc(bookingId)
          .update(updates);
      print('✅ Booking updated: $bookingId');
    } catch (e) {
      print('❌ Error updating booking: $e');
      rethrow;
    }
  }

  /// Delete booking from Firestore
  static Future<void> deleteBooking(String bookingId) async {
    try {
      await instance.collection(BOOKINGS_COLLECTION).doc(bookingId).delete();
      print('✅ Booking deleted: $bookingId');
    } catch (e) {
      print('❌ Error deleting booking: $e');
      rethrow;
    }
  }

  // ==================== GUEST OPERATIONS ====================

  /// Add a new guest to Firestore
  static Future<String> addGuest(Guest guest) async {
    try {
      final docRef = await instance.collection(GUESTS_COLLECTION).add({
        'name': guest.name,
        'email': guest.email,
        'phone': guest.phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Guest added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding guest: $e');
      rethrow;
    }
  }

  /// Get all guests from Firestore
  static Future<List<Guest>> getGuests() async {
    try {
      final querySnapshot = await instance
          .collection(GUESTS_COLLECTION)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Guest.fromSupabase({
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'],
          'phone': data['phone'],
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting guests: $e');
      return [];
    }
  }

  /// Update guest in Firestore
  static Future<void> updateGuest(
    String guestId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await instance.collection(GUESTS_COLLECTION).doc(guestId).update(updates);
      print('✅ Guest updated: $guestId');
    } catch (e) {
      print('❌ Error updating guest: $e');
      rethrow;
    }
  }

  /// Delete guest from Firestore
  static Future<void> deleteGuest(String guestId) async {
    try {
      await instance.collection(GUESTS_COLLECTION).doc(guestId).delete();
      print('✅ Guest deleted: $guestId');
    } catch (e) {
      print('❌ Error deleting guest: $e');
      rethrow;
    }
  }

  // ==================== ROOM OPERATIONS ====================

  /// Add a new room to Firestore
  static Future<String> addRoom(Room room) async {
    try {
      final docRef = await instance.collection(ROOMS_COLLECTION).add({
        'number': room.number,
        'type': room.type,
        'status': room.status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Room added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding room: $e');
      rethrow;
    }
  }

  /// Get all rooms from Firestore
  static Future<List<Room>> getRooms() async {
    try {
      final querySnapshot = await instance
          .collection(ROOMS_COLLECTION)
          .orderBy('number')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Room.fromMap({
          'id': doc.id,
          'number': data['number'] ?? '',
          'type': data['type'] ?? '',
          'status': data['status'] ?? 'available',
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting rooms: $e');
      return [];
    }
  }

  /// Get rooms as a real-time stream
  static Stream<List<Room>> getRoomsStream() {
    return instance
        .collection(ROOMS_COLLECTION)
        .orderBy('number')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Room.fromMap({
              'id': doc.id,
              'number': data['number'] ?? '',
              'type': data['type'] ?? '',
              'status': data['status'] ?? 'available',
            });
          }).toList(),
        );
  }

  /// Update room in Firestore
  static Future<void> updateRoom(
    String roomId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await instance.collection(ROOMS_COLLECTION).doc(roomId).update(updates);
      print('✅ Room updated: $roomId');
    } catch (e) {
      print('❌ Error updating room: $e');
      rethrow;
    }
  }

  /// Delete room from Firestore
  static Future<void> deleteRoom(String roomId) async {
    try {
      await instance.collection(ROOMS_COLLECTION).doc(roomId).delete();
      print('✅ Room deleted: $roomId');
    } catch (e) {
      print('❌ Error deleting room: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Store analytics data in Firestore
  static Future<void> recordAnalytics(
    String eventType,
    Map<String, dynamic> data,
  ) async {
    try {
      await instance.collection(ANALYTICS_COLLECTION).add({
        'eventType': eventType,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': data['userId'], // Optional user tracking
      });
      print('✅ Analytics recorded: $eventType');
    } catch (e) {
      print('❌ Error recording analytics: $e');
    }
  }

  /// Get analytics data
  static Future<List<Map<String, dynamic>>> getAnalytics({
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = instance.collection(ANALYTICS_COLLECTION);

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error getting analytics: $e');
      return [];
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get collection count
  static Future<int> getCollectionCount(String collectionName) async {
    try {
      final snapshot = await instance.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting collection count for $collectionName: $e');
      return 0;
    }
  }

  /// Get collection counts for all collections
  static Future<Map<String, int>> getCollectionCounts() async {
    try {
      final counts = <String, int>{};
      counts[BOOKINGS_COLLECTION] = await getCollectionCount(
        BOOKINGS_COLLECTION,
      );
      counts[GUESTS_COLLECTION] = await getCollectionCount(GUESTS_COLLECTION);
      counts[ROOMS_COLLECTION] = await getCollectionCount(ROOMS_COLLECTION);
      counts[PAYMENTS_COLLECTION] = await getCollectionCount(
        PAYMENTS_COLLECTION,
      );
      counts[USERS_COLLECTION] = await getCollectionCount(USERS_COLLECTION);
      counts[SETTINGS_COLLECTION] = await getCollectionCount(
        SETTINGS_COLLECTION,
      );
      counts[ANALYTICS_COLLECTION] = await getCollectionCount(
        ANALYTICS_COLLECTION,
      );
      return counts;
    } catch (e) {
      print('❌ Error getting collection counts: $e');
      return {};
    }
  }

  /// Batch write operation
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = instance.batch();

      for (final operation in operations) {
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>;
        final operationType =
            operation['type'] as String; // 'set', 'update', 'delete'

        DocumentReference docRef;
        if (docId != null) {
          docRef = instance.collection(collection).doc(docId);
        } else {
          docRef = instance.collection(collection).doc();
        }

        switch (operationType) {
          case 'set':
            batch.set(docRef, data);
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      print('✅ Batch operation completed: ${operations.length} operations');
    } catch (e) {
      print('❌ Error in batch operation: $e');
      rethrow;
    }
  }

  /// Listen to real-time updates for a collection
  static Stream<List<T>> listenToCollection<T>(
    String collectionName,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    return instance
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => fromMap({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  // ==================== STREAM OPERATIONS ====================

  /// Get bookings as a real-time stream
  static Stream<List<Booking>> getBookingsStream() {
    return instance
        .collection(BOOKINGS_COLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Booking.fromSupabase({
              'id': doc.id,
              'guest_name': data['guestName'] ?? '',
              'guest_email': data['guestEmail'],
              'guest_phone': data['guestPhone'],
              'room_number': data['roomNumber'] ?? '',
              'room_type': data['roomType'] ?? '',
              'room_status': data['roomStatus'] ?? '',
              'check_in': data['checkIn'] ?? '',
              'check_out': data['checkOut'] ?? '',
              'notes': data['notes'] ?? '',
              'deposit_paid': data['depositPaid'] ?? false,
              'payment_status': data['paymentStatus'] ?? 'Pending',
            });
          }).toList(),
        );
  }

  /// Get guests as a real-time stream
  static Stream<List<Guest>> getGuestsStream() {
    return instance
        .collection(GUESTS_COLLECTION)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Guest.fromSupabase({
              'id': doc.id,
              'name': data['name'] ?? '',
              'email': data['email'],
              'phone': data['phone'],
            });
          }).toList(),
        );
  }
}
