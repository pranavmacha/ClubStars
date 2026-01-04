import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyName = 'profile_name';
  static const String _keyRegNo = 'profile_reg_no';

  Future<void> saveProfile({
    String? name,
    String? regNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (regNo != null) await prefs.setString(_keyRegNo, regNo);
  }

  Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? '',
      'reg_no': prefs.getString(_keyRegNo) ?? '',
    };
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile['name']!.isNotEmpty || profile['reg_no']!.isNotEmpty;
  }
}
