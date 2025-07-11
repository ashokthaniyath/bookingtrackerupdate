// New Feature: Room Calendar Management Models
// These models support Google Calendar integration for resort room booking

class RoomCalendar {
  String? id; // Supabase ID
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
  DateTime? createdAt;
  DateTime? updatedAt;

  RoomCalendar({
    this.id,
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
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'room_id': roomId,
      'room_number': roomNumber,
      'room_type': roomType,
      'calendar_id': calendarId,
      'is_shared': isShared,
      'shared_with': sharedWith,
      'auto_accept_bookings': autoAcceptBookings,
      'color': color,
      'capacity': capacity,
      'location': location,
      'unavailable_hours': unavailableHours.map((h) => h.toSupabase()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create from Supabase data
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
      color: data['color'] ?? '#4285F4',
      capacity: data['capacity'] ?? 2,
      location: data['location'] ?? '',
      unavailableHours:
          (data['unavailable_hours'] as List<dynamic>?)
              ?.map((h) => UnavailableHours.fromSupabase(h))
              .toList() ??
          [],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
    );
  }
}

class UnavailableHours {
  String? id; // Supabase ID
  String title;
  int startHour;
  int endHour;
  List<int> daysOfWeek; // 1=Monday, 7=Sunday
  bool isRecurring;
  String reason;
  DateTime? createdAt;

  UnavailableHours({
    this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.daysOfWeek,
    this.isRecurring = true,
    this.reason = 'Maintenance',
    this.createdAt,
  });

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'start_hour': startHour,
      'end_hour': endHour,
      'days_of_week': daysOfWeek,
      'is_recurring': isRecurring,
      'reason': reason,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory UnavailableHours.fromSupabase(Map<String, dynamic> data) {
    return UnavailableHours(
      id: data['id']?.toString(),
      title: data['title'] ?? '',
      startHour: data['start_hour'] ?? 0,
      endHour: data['end_hour'] ?? 24,
      daysOfWeek: List<int>.from(data['days_of_week'] ?? []),
      isRecurring: data['is_recurring'] ?? true,
      reason: data['reason'] ?? 'Maintenance',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }
}

class CalendarNotification {
  String? id; // Supabase ID
  String bookingId;
  String guestEmail;
  DateTime scheduledTime;
  String type; // 'reminder', 'confirmation', 'cancellation'
  bool sent;
  String message;
  DateTime? createdAt;
  DateTime? sentAt;

  CalendarNotification({
    this.id,
    required this.bookingId,
    required this.guestEmail,
    required this.scheduledTime,
    required this.type,
    this.sent = false,
    this.message = '',
    this.createdAt,
    this.sentAt,
  });

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'booking_id': bookingId,
      'guest_email': guestEmail,
      'scheduled_time': scheduledTime.toIso8601String(),
      'type': type,
      'sent': sent,
      'message': message,
      'created_at': createdAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory CalendarNotification.fromSupabase(Map<String, dynamic> data) {
    return CalendarNotification(
      id: data['id']?.toString(),
      bookingId: data['booking_id'] ?? '',
      guestEmail: data['guest_email'] ?? '',
      scheduledTime: DateTime.parse(data['scheduled_time']),
      type: data['type'] ?? 'reminder',
      sent: data['sent'] ?? false,
      message: data['message'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      sentAt: data['sent_at'] != null ? DateTime.parse(data['sent_at']) : null,
    );
  }
}
