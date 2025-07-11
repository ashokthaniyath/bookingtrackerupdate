import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/payment.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Bookings operations
  static Future<List<Booking>> getBookings() async {
    try {
      final response = await _client.from('bookings').select();
      return response.map((data) => Booking.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  static Future<void> addBooking(Booking booking) async {
    try {
      await _client.from('bookings').insert(booking.toSupabase());
    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }

  static Future<void> updateBooking(String id, Booking booking) async {
    try {
      await _client.from('bookings').update(booking.toSupabase()).eq('id', id);
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }

  static Future<void> deleteBooking(String id) async {
    try {
      await _client.from('bookings').delete().eq('id', id);
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }

  // Rooms operations
  static Future<List<Room>> getRooms() async {
    try {
      final response = await _client.from('rooms').select();
      return response.map((data) => Room.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    }
  }

  static Future<void> addRoom(Room room) async {
    try {
      await _client.from('rooms').insert(room.toSupabase());
    } catch (e) {
      print('Error adding room: $e');
      rethrow;
    }
  }

  static Future<void> updateRoom(String id, Room room) async {
    try {
      await _client.from('rooms').update(room.toSupabase()).eq('id', id);
    } catch (e) {
      print('Error updating room: $e');
      rethrow;
    }
  }

  static Future<void> deleteRoom(String id) async {
    try {
      await _client.from('rooms').delete().eq('id', id);
    } catch (e) {
      print('Error deleting room: $e');
      rethrow;
    }
  }

  // Guests operations
  static Future<List<Guest>> getGuests() async {
    try {
      final response = await _client.from('guests').select();
      return response.map((data) => Guest.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching guests: $e');
      return [];
    }
  }

  static Future<void> addGuest(Guest guest) async {
    try {
      await _client.from('guests').insert(guest.toSupabase());
    } catch (e) {
      print('Error adding guest: $e');
      rethrow;
    }
  }

  static Future<void> updateGuest(String id, Guest guest) async {
    try {
      await _client.from('guests').update(guest.toSupabase()).eq('id', id);
    } catch (e) {
      print('Error updating guest: $e');
      rethrow;
    }
  }

  static Future<void> deleteGuest(String id) async {
    try {
      await _client.from('guests').delete().eq('id', id);
    } catch (e) {
      print('Error deleting guest: $e');
      rethrow;
    }
  }

  // Payments operations
  static Future<List<Payment>> getPayments() async {
    try {
      final response = await _client.from('payments').select();
      return response.map((data) => Payment.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  static Future<void> addPayment(Payment payment) async {
    try {
      await _client.from('payments').insert(payment.toSupabase());
    } catch (e) {
      print('Error adding payment: $e');
      rethrow;
    }
  }

  static Future<void> updatePayment(String id, Payment payment) async {
    try {
      await _client.from('payments').update(payment.toSupabase()).eq('id', id);
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  static Future<void> deletePayment(String id) async {
    try {
      await _client.from('payments').delete().eq('id', id);
    } catch (e) {
      print('Error deleting payment: $e');
      rethrow;
    }
  }

  // Authentication operations
  static Future<bool> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  static Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('Error signing up: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // Stream operations for real-time updates
  static Stream<List<Booking>> getBookingsStream() {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => Booking.fromSupabase(item)).toList());
  }

  static Stream<List<Room>> getRoomsStream() {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => Room.fromSupabase(item)).toList());
  }

  static Stream<List<Guest>> getGuestsStream() {
    return _client
        .from('guests')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => Guest.fromSupabase(item)).toList());
  }

  static Stream<List<Payment>> getPaymentsStream() {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((item) => Payment.fromSupabase(item)).toList());
  }
}
