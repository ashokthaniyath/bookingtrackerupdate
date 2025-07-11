class Room {
  String? id;
  String number;
  String type;
  String status;

  Room({
    this.id,
    required this.number,
    required this.type,
    required this.status,
  });

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'number': number,
      'type': type,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Room.fromSupabase(Map<String, dynamic> data) {
    return Room(
      id: data['id']?.toString(),
      number: data['number'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'available',
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {'number': number, 'type': type, 'status': status};
  }

  factory Room.fromMap(Map<String, dynamic> map, {String? firestoreId}) {
    return Room(
      number: map['number'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
    );
  }
}
