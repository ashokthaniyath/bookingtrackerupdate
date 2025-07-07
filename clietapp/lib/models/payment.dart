import 'package:hive/hive.dart';
import 'guest.dart';
part 'payment.g.dart';

@HiveType(typeId: 3)
class Payment extends HiveObject {
  @HiveField(0)
  Guest guest;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String status; // Paid, Pending

  @HiveField(3)
  DateTime date;

  Payment({
    required this.guest,
    required this.amount,
    required this.status,
    required this.date,
  });
}
