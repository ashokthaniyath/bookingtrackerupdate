// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_calendar.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomCalendarAdapter extends TypeAdapter<RoomCalendar> {
  @override
  final int typeId = 4;

  @override
  RoomCalendar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoomCalendar(
      roomId: fields[0] as String,
      roomNumber: fields[1] as String,
      roomType: fields[2] as String,
      calendarId: fields[3] as String,
      isShared: fields[4] as bool,
      sharedWith: (fields[5] as List).cast<String>(),
      autoAcceptBookings: fields[6] as bool,
      color: fields[7] as String,
      capacity: fields[8] as int,
      location: fields[9] as String,
      unavailableHours: (fields[10] as List).cast<UnavailableHours>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoomCalendar obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.roomNumber)
      ..writeByte(2)
      ..write(obj.roomType)
      ..writeByte(3)
      ..write(obj.calendarId)
      ..writeByte(4)
      ..write(obj.isShared)
      ..writeByte(5)
      ..write(obj.sharedWith)
      ..writeByte(6)
      ..write(obj.autoAcceptBookings)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.capacity)
      ..writeByte(9)
      ..write(obj.location)
      ..writeByte(10)
      ..write(obj.unavailableHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomCalendarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnavailableHoursAdapter extends TypeAdapter<UnavailableHours> {
  @override
  final int typeId = 5;

  @override
  UnavailableHours read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnavailableHours(
      title: fields[0] as String,
      startHour: fields[1] as int,
      endHour: fields[2] as int,
      daysOfWeek: (fields[3] as List).cast<int>(),
      isRecurring: fields[4] as bool,
      reason: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UnavailableHours obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startHour)
      ..writeByte(2)
      ..write(obj.endHour)
      ..writeByte(3)
      ..write(obj.daysOfWeek)
      ..writeByte(4)
      ..write(obj.isRecurring)
      ..writeByte(5)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnavailableHoursAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalendarNotificationAdapter extends TypeAdapter<CalendarNotification> {
  @override
  final int typeId = 6;

  @override
  CalendarNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarNotification(
      bookingId: fields[0] as String,
      guestEmail: fields[1] as String,
      scheduledTime: fields[2] as DateTime,
      type: fields[3] as String,
      sent: fields[4] as bool,
      message: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarNotification obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.bookingId)
      ..writeByte(1)
      ..write(obj.guestEmail)
      ..writeByte(2)
      ..write(obj.scheduledTime)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.sent)
      ..writeByte(5)
      ..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
