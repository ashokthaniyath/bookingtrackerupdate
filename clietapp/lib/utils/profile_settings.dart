import 'package:hive/hive.dart';

class ProfileSettings {
  static const String _boxName = 'profile_settings';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  static Future<void> saveProfile(String name, String email) async {
    final box = await _getBox();
    await box.put('name', name);
    await box.put('email', email);
  }

  static Future<Map<String, String>> loadProfile() async {
    final box = await _getBox();
    return {
      'name': box.get('name', defaultValue: 'Host Name'),
      'email': box.get('email', defaultValue: 'host@email.com'),
    };
  }
}
