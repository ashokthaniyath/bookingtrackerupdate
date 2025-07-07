import 'package:hive/hive.dart';
part 'room.g.dart';

@HiveType(typeId: 1)
class Room extends HiveObject {
  @HiveField(0)
  String number;

  @HiveField(1)
  String type;

  @HiveField(2)
  String status;

  // Optionally add Firestore document ID for sync
  @HiveField(3)
  String? firestoreId;

  Room({
    required this.number,
    required this.type,
    required this.status,
    this.firestoreId,
  });

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {'number': number, 'type': type, 'status': status};
  }

  factory Room.fromMap(Map<String, dynamic> map, {String? firestoreId}) {
    return Room(
      number: map['number'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      firestoreId: firestoreId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'number': number, 'type': type, 'status': status};
  }

  factory Room.fromFirestore(Map<String, dynamic> map, String firestoreId) {
    return Room(
      number: map['number'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      firestoreId: firestoreId,
    );
  }

  // For Hive compatibility
  factory Room.fromHive(Map<dynamic, dynamic> map) {
    return Room(
      number: map['number'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      firestoreId: map['firestoreId'],
    );
  }

  Map<String, dynamic> toHive() {
    return {
      'number': number,
      'type': type,
      'status': status,
      'firestoreId': firestoreId,
    };
  }
}
