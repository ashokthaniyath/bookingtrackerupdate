import 'guest.dart';

class Payment {
  String? id;
  Guest guest;
  double amount;
  String status; // Paid, Pending
  DateTime date;

  Payment({
    this.id,
    required this.guest,
    required this.amount,
    required this.status,
    required this.date,
  });

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'guest_name': guest.name,
      'guest_email': guest.email,
      'guest_phone': guest.phone,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Payment.fromSupabase(Map<String, dynamic> data) {
    return Payment(
      id: data['id']?.toString(),
      guest: Guest(
        name: data['guest_name'] ?? '',
        email: data['guest_email'],
        phone: data['guest_phone'],
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {
      'guest': guest.toMap(),
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      guest: Guest(
        id: map['guestId'],
        name: map['guestName'] ?? '',
        email: map['guestEmail'],
        phone: map['guestPhone'],
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
