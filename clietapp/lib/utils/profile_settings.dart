import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettings {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response?['settings'] ?? {};
    } catch (e) {
      print('Error getting settings: $e');
      return {};
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'settings': settings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      print('Error getting profile: $e');
      return {};
    }
  }

  static Future<void> saveProfile(String name, String email) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'name': name,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving profile: $e');
    }
  }
}
