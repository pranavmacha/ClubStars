import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/club_mail.dart';

class ApiService {
  // Use 192.168.0.106 (your machine's local IP) for physical device
  static const String baseUrl = 'http://192.168.0.106:8000';

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email.toLowerCase());
  }

  Future<List<ClubMail>> fetchClubMails() async {
    try {
      final email = await getUserEmail();
      final response = await http.get(
        Uri.parse('$baseUrl/club-mails'),
        headers: email != null ? {'user-email': email} : {},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ClubMail> mails =
            body.map((dynamic item) => ClubMail.fromJson(item)).toList();
        return mails;
      } else {
        throw Exception('Failed to load club mails');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<int> syncPastMails() async {
    try {
      final email = await getUserEmail();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/sync'),
        headers: email != null ? {'user-email': email} : {},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['synced_links'] ?? 0;
      } else {
        throw Exception('Failed to sync historical mails');
      }
    } catch (e) {
      throw Exception('Error syncing: $e');
    }
  }

  String get loginUrl => '$baseUrl/auth/google/login';
}
