import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyName = 'profile_name';
  static const String _keyRegNo = 'profile_reg_no';
  static const String _keyPhone = 'profile_phone';
  static const String _keyBranch = 'profile_branch';
  static const String _keyYear = 'profile_year';
  static const String _keyGender = 'profile_gender';
  static const String _keyHostel = 'profile_hostel';
  static const String _keyWhatsapp = 'profile_whatsapp';

  Future<void> saveProfile({
    String? name,
    String? regNo,
    String? phone,
    String? branch,
    String? year,
    String? gender,
    String? hostel,
    String? whatsapp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (regNo != null) await prefs.setString(_keyRegNo, regNo);
    if (phone != null) await prefs.setString(_keyPhone, phone);
    if (branch != null) await prefs.setString(_keyBranch, branch);
    if (year != null) await prefs.setString(_keyYear, year);
    if (gender != null) await prefs.setString(_keyGender, gender);
    if (hostel != null) await prefs.setString(_keyHostel, hostel);
    if (whatsapp != null) await prefs.setString(_keyWhatsapp, whatsapp);
  }

  Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? '',
      'reg_no': prefs.getString(_keyRegNo) ?? '',
      'phone': prefs.getString(_keyPhone) ?? '',
      'branch': prefs.getString(_keyBranch) ?? '',
      'year': prefs.getString(_keyYear) ?? '',
      'gender': prefs.getString(_keyGender) ?? '',
      'hostel': prefs.getString(_keyHostel) ?? '',
      'whatsapp': prefs.getString(_keyWhatsapp) ?? '',
    };
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile['name']!.isNotEmpty || profile['reg_no']!.isNotEmpty;
  }
}
