class Guest {
  String? id;
  String name;
  String? email;
  String? phone;

  Guest({this.id, required this.name, this.email, this.phone});

  // Supabase Integration - Serialization methods
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
      id: data['id']?.toString(),
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'phone': phone};
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
    );
  }
}
