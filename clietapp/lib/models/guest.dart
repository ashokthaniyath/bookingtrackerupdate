import 'package:hive/hive.dart';
part 'guest.g.dart';

@HiveType(typeId: 0)
class Guest extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? email;

  @HiveField(2)
  String? phone;

  Guest({required this.name, this.email, this.phone});
}
