// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingAdapter extends TypeAdapter<Booking> {
  @override
  final int typeId = 2;

  @override
  Booking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Booking(
      guest: fields[0] as Guest,
      room: fields[1] as Room,
      checkIn: fields[2] as DateTime,
      checkOut: fields[3] as DateTime,
      notes: fields[4] as String,
      depositPaid: fields[5] as bool,
      paymentStatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Booking obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.guest)
      ..writeByte(1)
      ..write(obj.room)
      ..writeByte(2)
      ..write(obj.checkIn)
      ..writeByte(3)
      ..write(obj.checkOut)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.depositPaid)
      ..writeByte(6)
      ..write(obj.paymentStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
