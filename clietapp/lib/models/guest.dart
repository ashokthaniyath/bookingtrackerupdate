import 'package:hive/hive.dart';
part 'guest.g.dart';

@HiveType(typeId: 0)
class Guest extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? phone;

  Guest({required this.name, this.email, this.phone});

  // Firebase serialization methods
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'phone': phone};
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
    );
  }

  // Backend: Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Guest.fromSupabase(Map<String, dynamic> data) {
    return Guest(
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
    );
  }
}
