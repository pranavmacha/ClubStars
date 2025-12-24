import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/club_mail.dart';

class ApiService {
  // Use 192.168.0.106 (your machine's local IP) for physical device
  static const String baseUrl = 'http://192.168.0.106:8000';

  Future<List<ClubMail>> fetchClubMails() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/club-mails'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ClubMail> mails = body
            .map((dynamic item) => ClubMail.fromJson(item))
            .toList();
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
      final response = await http.post(Uri.parse('$baseUrl/auth/google/sync'));

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
}
