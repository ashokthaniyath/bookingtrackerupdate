import 'package:hive/hive.dart';
part 'room_calendar.g.dart';

@HiveType(typeId: 4)
class RoomCalendar extends HiveObject {
  @HiveField(0)
  String roomId;

  @HiveField(1)
  String roomNumber;

  @HiveField(2)
  String roomType;

  @HiveField(3)
  String calendarId; // Google Calendar ID

  @HiveField(4)
  bool isShared;

  @HiveField(5)
  List<String> sharedWith; // Email addresses with access

  @HiveField(6)
  bool autoAcceptBookings;

  @HiveField(7)
  String color;

  @HiveField(8)
  int capacity;

  @HiveField(9)
  String location;

  @HiveField(10)
  List<UnavailableHours> unavailableHours;

  RoomCalendar({
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.calendarId,
    this.isShared = false,
    this.sharedWith = const [],
    this.autoAcceptBookings = true,
    this.color = '#4285F4',
    this.capacity = 2,
    this.location = '',
    this.unavailableHours = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'calendarId': calendarId,
      'isShared': isShared,
      'sharedWith': sharedWith,
      'autoAcceptBookings': autoAcceptBookings,
      'color': color,
      'capacity': capacity,
      'location': location,
      'unavailableHours': unavailableHours.map((e) => e.toJson()).toList(),
    };
  }

  factory RoomCalendar.fromJson(Map<String, dynamic> json) {
    return RoomCalendar(
      roomId: json['roomId'],
      roomNumber: json['roomNumber'],
      roomType: json['roomType'],
      calendarId: json['calendarId'],
      isShared: json['isShared'] ?? false,
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      autoAcceptBookings: json['autoAcceptBookings'] ?? true,
      color: json['color'] ?? '#4285F4',
      capacity: json['capacity'] ?? 2,
      location: json['location'] ?? '',
      unavailableHours:
          (json['unavailableHours'] as List?)
              ?.map((e) => UnavailableHours.fromJson(e))
              .toList() ??
          [],
    );
  }
}

@HiveType(typeId: 5)
class UnavailableHours extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  int startHour;

  @HiveField(2)
  int endHour;

  @HiveField(3)
  List<int> daysOfWeek; // 1=Monday, 7=Sunday

  @HiveField(4)
  bool isRecurring;

  @HiveField(5)
  String reason;

  UnavailableHours({
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.daysOfWeek,
    this.isRecurring = true,
    this.reason = 'Maintenance',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startHour': startHour,
      'endHour': endHour,
      'daysOfWeek': daysOfWeek,
      'isRecurring': isRecurring,
      'reason': reason,
    };
  }

  factory UnavailableHours.fromJson(Map<String, dynamic> json) {
    return UnavailableHours(
      title: json['title'],
      startHour: json['startHour'],
      endHour: json['endHour'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      isRecurring: json['isRecurring'] ?? true,
      reason: json['reason'] ?? 'Maintenance',
    );
  }
}

@HiveType(typeId: 6)
class CalendarNotification extends HiveObject {
  @HiveField(0)
  String bookingId;

  @HiveField(1)
  String guestEmail;

  @HiveField(2)
  DateTime scheduledTime;

  @HiveField(3)
  String type; // 'reminder', 'confirmation', 'cancellation'

  @HiveField(4)
  bool sent;

  @HiveField(5)
  String message;

  CalendarNotification({
    required this.bookingId,
    required this.guestEmail,
    required this.scheduledTime,
    required this.type,
    this.sent = false,
    this.message = '',
  });
}
