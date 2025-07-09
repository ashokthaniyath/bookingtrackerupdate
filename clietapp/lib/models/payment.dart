import 'package:hive/hive.dart';
import 'guest.dart';
part 'payment.g.dart';

@HiveType(typeId: 3)
class Payment extends HiveObject {
  @HiveField(0)
  Guest guest;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String status; // Paid, Pending

  @HiveField(3)
  DateTime date;

  Payment({
    required this.guest,
    required this.amount,
    required this.status,
    required this.date,
  });

  // Backend: Supabase Integration - Serialization methods
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
}
