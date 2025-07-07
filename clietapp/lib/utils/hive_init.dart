import 'package:hive/hive.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../models/payment.dart';

// Placeholder for Hive initialization logic
Future<void> initializeHiveBoxes() async {
  Hive.registerAdapter(GuestAdapter());
  Hive.registerAdapter(RoomAdapter());
  Hive.registerAdapter(BookingAdapter());
  Hive.registerAdapter(PaymentAdapter());
  await Hive.openBox<Booking>('bookings');
  await Hive.openBox<Room>('rooms');
  await Hive.openBox<Guest>('guests');
  await Hive.openBox<Payment>('payments');
}
