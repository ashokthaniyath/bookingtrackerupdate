import 'guest.dart';
import 'room.dart';

class Booking {
  String? id;
  Guest guest;
  Room room;
  DateTime checkIn;
  DateTime checkOut;
  String notes;
  bool depositPaid;
  String paymentStatus;

  Booking({
    this.id,
    required this.guest,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    this.notes = '',
    this.depositPaid = false,
    this.paymentStatus = 'Pending',
  });

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'guest_name': guest.name,
      'guest_email': guest.email,
      'guest_phone': guest.phone,
      'room_number': room.number,
      'room_type': room.type,
      'room_status': room.status,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut.toIso8601String(),
      'notes': notes,
      'deposit_paid': depositPaid,
      'payment_status': paymentStatus,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Booking.fromSupabase(Map<String, dynamic> data) {
    return Booking(
      id: data['id']?.toString(),
      guest: Guest(
        name: data['guest_name'] ?? '',
        email: data['guest_email'],
        phone: data['guest_phone'],
      ),
      room: Room(
        number: data['room_number'] ?? '',
        type: data['room_type'] ?? '',
        status: data['room_status'] ?? 'available',
      ),
      checkIn: DateTime.parse(
        data['check_in'] ?? DateTime.now().toIso8601String(),
      ),
      checkOut: DateTime.parse(
        data['check_out'] ?? DateTime.now().toIso8601String(),
      ),
      notes: data['notes'] ?? '',
      depositPaid: data['deposit_paid'] ?? false,
      paymentStatus: data['payment_status'] ?? 'Pending',
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {
      'guest': guest.toMap(),
      'room': room.toMap(),
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'notes': notes,
      'depositPaid': depositPaid,
      'paymentStatus': paymentStatus,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      guest: Guest.fromMap(map['guest'] ?? {}),
      room: Room.fromMap(map['room'] ?? {}),
      checkIn: DateTime.parse(
        map['checkIn'] ?? DateTime.now().toIso8601String(),
      ),
      checkOut: DateTime.parse(
        map['checkOut'] ?? DateTime.now().toIso8601String(),
      ),
      notes: map['notes'] ?? '',
      depositPaid: map['depositPaid'] ?? false,
      paymentStatus: map['paymentStatus'] ?? 'Pending',
    );
  }
}
