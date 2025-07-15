// Simple profile settings placeholder for Firebase migration
class ProfileSettings {
  static Future<Map<String, String>> getProfile() async {
    // Return default profile data
    return {'name': 'Demo User', 'email': 'demo@example.com'};
  }

  static Future<void> saveProfile(String name, String email) async {
    // TODO: Implement with Firestore
    print('Profile saved: $name, $email');
  }
}
