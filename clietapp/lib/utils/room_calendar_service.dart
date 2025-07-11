import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_calendar_simple.dart';

class RoomCalendarService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Room Calendar operations
  static Future<List<RoomCalendar>> getRoomCalendars() async {
    try {
      final response = await _client.from('room_calendars').select();
      return response.map((data) => RoomCalendar.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching room calendars: $e');
      return [];
    }
  }

  static Future<RoomCalendar?> getRoomCalendarByRoomId(String roomId) async {
    try {
      final response = await _client
          .from('room_calendars')
          .select()
          .eq('room_id', roomId)
          .maybeSingle();

      if (response != null) {
        return RoomCalendar.fromSupabase(response);
      }
      return null;
    } catch (e) {
      print('Error fetching room calendar: $e');
      return null;
    }
  }

  static Future<void> addRoomCalendar(RoomCalendar calendar) async {
    try {
      await _client.from('room_calendars').insert(calendar.toSupabase());
    } catch (e) {
      print('Error adding room calendar: $e');
      rethrow;
    }
  }

  static Future<void> updateRoomCalendar(
    String id,
    RoomCalendar calendar,
  ) async {
    try {
      await _client
          .from('room_calendars')
          .update(calendar.toSupabase())
          .eq('id', id);
    } catch (e) {
      print('Error updating room calendar: $e');
      rethrow;
    }
  }

  static Future<void> deleteRoomCalendar(String id) async {
    try {
      await _client.from('room_calendars').delete().eq('id', id);
    } catch (e) {
      print('Error deleting room calendar: $e');
      rethrow;
    }
  }

  // Unavailable Hours operations
  static Future<List<UnavailableHours>> getUnavailableHours(
    String roomCalendarId,
  ) async {
    try {
      final response = await _client
          .from('unavailable_hours')
          .select()
          .eq('room_calendar_id', roomCalendarId);
      return response
          .map((data) => UnavailableHours.fromSupabase(data))
          .toList();
    } catch (e) {
      print('Error fetching unavailable hours: $e');
      return [];
    }
  }

  static Future<void> addUnavailableHours(
    String roomCalendarId,
    UnavailableHours hours,
  ) async {
    try {
      final data = hours.toSupabase();
      data['room_calendar_id'] = roomCalendarId;
      await _client.from('unavailable_hours').insert(data);
    } catch (e) {
      print('Error adding unavailable hours: $e');
      rethrow;
    }
  }

  static Future<void> updateUnavailableHours(
    String id,
    UnavailableHours hours,
  ) async {
    try {
      await _client
          .from('unavailable_hours')
          .update(hours.toSupabase())
          .eq('id', id);
    } catch (e) {
      print('Error updating unavailable hours: $e');
      rethrow;
    }
  }

  static Future<void> deleteUnavailableHours(String id) async {
    try {
      await _client.from('unavailable_hours').delete().eq('id', id);
    } catch (e) {
      print('Error deleting unavailable hours: $e');
      rethrow;
    }
  }

  // Calendar Notifications operations
  static Future<List<CalendarNotification>> getCalendarNotifications() async {
    try {
      final response = await _client.from('calendar_notifications').select();
      return response
          .map((data) => CalendarNotification.fromSupabase(data))
          .toList();
    } catch (e) {
      print('Error fetching calendar notifications: $e');
      return [];
    }
  }

  static Future<List<CalendarNotification>> getPendingNotifications() async {
    try {
      final response = await _client
          .from('calendar_notifications')
          .select()
          .eq('sent', false)
          .lte('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time');
      return response
          .map((data) => CalendarNotification.fromSupabase(data))
          .toList();
    } catch (e) {
      print('Error fetching pending notifications: $e');
      return [];
    }
  }

  static Future<void> addCalendarNotification(
    CalendarNotification notification,
  ) async {
    try {
      await _client
          .from('calendar_notifications')
          .insert(notification.toSupabase());
    } catch (e) {
      print('Error adding calendar notification: $e');
      rethrow;
    }
  }

  static Future<void> markNotificationAsSent(String id) async {
    try {
      await _client
          .from('calendar_notifications')
          .update({'sent': true, 'sent_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      print('Error marking notification as sent: $e');
      rethrow;
    }
  }

  static Future<void> deleteCalendarNotification(String id) async {
    try {
      await _client.from('calendar_notifications').delete().eq('id', id);
    } catch (e) {
      print('Error deleting calendar notification: $e');
      rethrow;
    }
  }

  // Stream operations for real-time updates
  static Stream<List<RoomCalendar>> getRoomCalendarsStream() {
    return _client
        .from('room_calendars')
        .stream(primaryKey: ['id'])
        .map(
          (data) =>
              data.map((item) => RoomCalendar.fromSupabase(item)).toList(),
        );
  }

  static Stream<List<CalendarNotification>> getCalendarNotificationsStream() {
    return _client
        .from('calendar_notifications')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .map((item) => CalendarNotification.fromSupabase(item))
              .toList(),
        );
  }

  // Google Calendar Integration helpers
  static Future<void> syncWithGoogleCalendar(String roomCalendarId) async {
    // TODO: Implement Google Calendar API integration
    try {
      final roomCalendar = await _client
          .from('room_calendars')
          .select()
          .eq('id', roomCalendarId)
          .single();

      final calendarId = roomCalendar['calendar_id'];

      // Here you would integrate with Google Calendar API
      // to sync events, create calendar if needed, etc.
      print('Syncing with Google Calendar: $calendarId');
    } catch (e) {
      print('Error syncing with Google Calendar: $e');
      rethrow;
    }
  }

  static Future<String> createGoogleCalendar(
    String roomNumber,
    String roomType,
  ) async {
    // TODO: Implement Google Calendar creation
    try {
      // This would create a new calendar in Google Calendar
      // and return the calendar ID
      final calendarId =
          'room_${roomNumber}_${DateTime.now().millisecondsSinceEpoch}';

      print('Created Google Calendar for Room $roomNumber: $calendarId');
      return calendarId;
    } catch (e) {
      print('Error creating Google Calendar: $e');
      rethrow;
    }
  }
}
