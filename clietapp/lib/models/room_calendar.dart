class RoomCalendar {
  String? id;
  String roomId;
  String roomNumber;
  String roomType;
  String calendarId; // Google Calendar ID
  bool isShared;
  List<String> sharedWith; // Email addresses with access
  bool autoAcceptBookings;
  String color;
  Map<String, dynamic> settings;
  DateTime createdAt;
  DateTime lastSyncedAt;

  RoomCalendar({
    this.id,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.calendarId,
    this.isShared = false,
    this.sharedWith = const [],
    this.autoAcceptBookings = true,
    this.color = '#2196F3',
    this.settings = const {},
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastSyncedAt = lastSyncedAt ?? DateTime.now();

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'room_id': roomId,
      'room_number': roomNumber,
      'room_type': roomType,
      'calendar_id': calendarId,
      'is_shared': isShared,
      'shared_with': sharedWith,
      'auto_accept_bookings': autoAcceptBookings,
      'color': color,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  factory RoomCalendar.fromSupabase(Map<String, dynamic> data) {
    return RoomCalendar(
      id: data['id']?.toString(),
      roomId: data['room_id'] ?? '',
      roomNumber: data['room_number'] ?? '',
      roomType: data['room_type'] ?? '',
      calendarId: data['calendar_id'] ?? '',
      isShared: data['is_shared'] ?? false,
      sharedWith: List<String>.from(data['shared_with'] ?? []),
      autoAcceptBookings: data['auto_accept_bookings'] ?? true,
      color: data['color'] ?? '#2196F3',
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastSyncedAt: DateTime.parse(
        data['last_synced_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'calendarId': calendarId,
      'isShared': isShared,
      'sharedWith': sharedWith,
      'autoAcceptBookings': autoAcceptBookings,
      'color': color,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }

  factory RoomCalendar.fromMap(Map<String, dynamic> map) {
    return RoomCalendar(
      roomId: map['roomId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      roomType: map['roomType'] ?? '',
      calendarId: map['calendarId'] ?? '',
      isShared: map['isShared'] ?? false,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      autoAcceptBookings: map['autoAcceptBookings'] ?? true,
      color: map['color'] ?? '#2196F3',
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastSyncedAt: DateTime.parse(
        map['lastSyncedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class CalendarEvent {
  String? id;
  String eventId;
  String roomCalendarId;
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  bool isAllDay;

  CalendarEvent({
    this.id,
    required this.eventId,
    required this.roomCalendarId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
  });

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'event_id': eventId,
      'room_calendar_id': roomCalendarId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory CalendarEvent.fromSupabase(Map<String, dynamic> data) {
    return CalendarEvent(
      id: data['id']?.toString(),
      eventId: data['event_id'] ?? '',
      roomCalendarId: data['room_calendar_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: DateTime.parse(
        data['start_time'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        data['end_time'] ?? DateTime.now().toIso8601String(),
      ),
      isAllDay: data['is_all_day'] ?? false,
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'roomCalendarId': roomCalendarId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      eventId: map['eventId'] ?? '',
      roomCalendarId: map['roomCalendarId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(
        map['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        map['endTime'] ?? DateTime.now().toIso8601String(),
      ),
      isAllDay: map['isAllDay'] ?? false,
    );
  }
}

class RoomCalendarConfiguration {
  String? id;
  String roomId;
  String timezone;
  Map<String, bool> workingDays;
  String workingHoursStart;
  String workingHoursEnd;
  int bufferTimeMinutes;

  RoomCalendarConfiguration({
    this.id,
    required this.roomId,
    this.timezone = 'UTC',
    this.workingDays = const {
      'monday': true,
      'tuesday': true,
      'wednesday': true,
      'thursday': true,
      'friday': true,
      'saturday': true,
      'sunday': true,
    },
    this.workingHoursStart = '00:00',
    this.workingHoursEnd = '23:59',
    this.bufferTimeMinutes = 15,
  });

  // Supabase Integration - Serialization methods
  Map<String, dynamic> toSupabase() {
    return {
      'room_id': roomId,
      'timezone': timezone,
      'working_days': workingDays,
      'working_hours_start': workingHoursStart,
      'working_hours_end': workingHoursEnd,
      'buffer_time_minutes': bufferTimeMinutes,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory RoomCalendarConfiguration.fromSupabase(Map<String, dynamic> data) {
    return RoomCalendarConfiguration(
      id: data['id']?.toString(),
      roomId: data['room_id'] ?? '',
      timezone: data['timezone'] ?? 'UTC',
      workingDays: Map<String, bool>.from(data['working_days'] ?? {}),
      workingHoursStart: data['working_hours_start'] ?? '00:00',
      workingHoursEnd: data['working_hours_end'] ?? '23:59',
      bufferTimeMinutes: data['buffer_time_minutes'] ?? 15,
    );
  }

  // Legacy support for existing serialization
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'timezone': timezone,
      'workingDays': workingDays,
      'workingHoursStart': workingHoursStart,
      'workingHoursEnd': workingHoursEnd,
      'bufferTimeMinutes': bufferTimeMinutes,
    };
  }

  factory RoomCalendarConfiguration.fromMap(Map<String, dynamic> map) {
    return RoomCalendarConfiguration(
      roomId: map['roomId'] ?? '',
      timezone: map['timezone'] ?? 'UTC',
      workingDays: Map<String, bool>.from(map['workingDays'] ?? {}),
      workingHoursStart: map['workingHoursStart'] ?? '00:00',
      workingHoursEnd: map['workingHoursEnd'] ?? '23:59',
      bufferTimeMinutes: map['bufferTimeMinutes'] ?? 15,
    );
  }
}
