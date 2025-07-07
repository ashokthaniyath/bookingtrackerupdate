import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Bookings
  Stream<QuerySnapshot> bookingsStream() {
    return _db.collection('bookings').orderBy('checkIn').snapshots();
  }

  Future<void> addBooking(Map<String, dynamic> data) async {
    await _db.collection('bookings').add(data);
  }

  Future<void> updateBooking(String id, Map<String, dynamic> data) async {
    await _db.collection('bookings').doc(id).update(data);
  }

  Future<void> deleteBooking(String id) async {
    await _db.collection('bookings').doc(id).delete();
  }

  // Guests
  Stream<QuerySnapshot> guestsStream() {
    return _db.collection('guests').orderBy('name').snapshots();
  }

  Future<void> addGuest(Map<String, dynamic> data) async {
    await _db.collection('guests').add(data);
  }

  // Rooms
  Stream<QuerySnapshot> roomsStream() {
    return _db.collection('rooms').orderBy('number').snapshots();
  }

  Future<void> addRoom(Map<String, dynamic> data) async {
    await _db.collection('rooms').add(data);
  }

  // Payments
  Stream<QuerySnapshot> paymentsStream() {
    return _db
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addPayment(Map<String, dynamic> data) async {
    await _db.collection('payments').add(data);
  }
}
