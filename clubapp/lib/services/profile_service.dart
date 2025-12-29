import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyName = 'profile_name';
  static const String _keyRegNo = 'profile_reg_no';
  static const String _keyPhone = 'profile_phone';

  Future<void> saveProfile({
    String? name,
    String? regNo,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (regNo != null) await prefs.setString(_keyRegNo, regNo);
    if (phone != null) await prefs.setString(_keyPhone, phone);
  }

  Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? '',
      'reg_no': prefs.getString(_keyRegNo) ?? '',
      'phone': prefs.getString(_keyPhone) ?? '',
    };
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile['name']!.isNotEmpty || profile['reg_no']!.isNotEmpty;
  }
}
