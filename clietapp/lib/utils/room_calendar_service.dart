import '../models/room_calendar.dart';

// Room calendar service placeholder for Firebase migration
class RoomCalendarService {
  static Future<List<RoomCalendar>> getRoomCalendars() async {
    // Return empty list for now
    return [];
  }

  static Future<void> addRoomCalendar(RoomCalendar calendar) async {
    // TODO: Implement with Firestore
    print('Room calendar added: ${calendar.roomId}');
  }

  static Future<void> updateRoomCalendar(
    String id,
    RoomCalendar calendar,
  ) async {
    // TODO: Implement with Firestore
    print('Room calendar updated: $id');
  }

  static Future<void> deleteRoomCalendar(String id) async {
    // TODO: Implement with Firestore
    print('Room calendar deleted: $id');
  }
}
