import 'package:hive/hive.dart';
import 'guest.dart';
import 'room.dart';
part 'booking.g.dart';

@HiveType(typeId: 2)
class Booking extends HiveObject {
  @HiveField(0)
  Guest guest;

  @HiveField(1)
  Room room;

  @HiveField(2)
  DateTime checkIn;

  @HiveField(3)
  DateTime checkOut;

  @HiveField(4)
  String notes;

  @HiveField(5)
  bool depositPaid;

  @HiveField(6)
  String paymentStatus;

  Booking({
    required this.guest,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    this.notes = '',
    this.depositPaid = false,
    this.paymentStatus = 'Pending',
  });
}
