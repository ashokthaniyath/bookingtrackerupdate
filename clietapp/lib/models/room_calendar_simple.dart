// New Feature: Room Calendar Management Models
// These models support Google Calendar integration for resort room booking

class RoomCalendar {
  String roomId;
  String roomNumber;
  String roomType;
  String calendarId; // Google Calendar ID
  bool isShared;
  List<String> sharedWith; // Email addresses with access
  bool autoAcceptBookings;
  String color;
  int capacity;
  String location;
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
}

class UnavailableHours {
  String title;
  int startHour;
  int endHour;
  List<int> daysOfWeek; // 1=Monday, 7=Sunday
  bool isRecurring;
  String reason;

  UnavailableHours({
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.daysOfWeek,
    this.isRecurring = true,
    this.reason = 'Maintenance',
  });
}

class CalendarNotification {
  String bookingId;
  String guestEmail;
  DateTime scheduledTime;
  String type; // 'reminder', 'confirmation', 'cancellation'
  bool sent;
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
