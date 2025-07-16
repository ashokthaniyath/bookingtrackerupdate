class Room {
  String? id;
  String number;
  String type;
  String status;
  double pricePerNight;

  Room({
    this.id,
    required this.number,
    required this.type,
    required this.status,
    this.pricePerNight = 100.0,
  });

  // Local serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'status': status,
      'pricePerNight': pricePerNight,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map, {String? firestoreId}) {
    return Room(
      id: map['id'] ?? firestoreId,
      number: map['number'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'available',
      pricePerNight: map['pricePerNight']?.toDouble() ?? 100.0,
    );
  }
}
