import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/club_mail.dart';
import '../services/profile_service.dart';

class EventDetailScreen extends StatelessWidget {
  static const route = '/event-detail';
  final ClubMail mail;

  const EventDetailScreen({super.key, required this.mail});

  Future<void> _launchUrl(String url) async {
    String finalUrl = url;

    // Auto-fill logic
    if (mail.fieldMappings != null && mail.fieldMappings!.isNotEmpty) {
      final profile = await ProfileService().getProfile();
      final Uri uri = Uri.parse(url);
      final Map<String, String> params = Map.from(uri.queryParameters);

      mail.fieldMappings!.forEach((key, entryId) {
        if (key == 'name' && profile['name']!.isNotEmpty) {
          params[entryId] = profile['name']!;
        } else if (key == 'reg_no' && profile['reg_no']!.isNotEmpty) {
          params[entryId] = profile['reg_no']!;
        } else if (key == 'phone' && profile['phone']!.isNotEmpty) {
          params[entryId] = profile['phone']!;
        } else if (key == 'email' && mail.recipient != null) {
          params[entryId] = mail.recipient!;
        }
      });

      finalUrl = uri.replace(queryParameters: params).toString();
      debugPrint('Launching pre-filled URL: $finalUrl');
    }

    final Uri finalUri = Uri.parse(finalUrl);
    if (!await launchUrl(finalUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $finalUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mail.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${mail.sender}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.calendar_today, 'Date', mail.date),
            _buildDetailRow(Icons.access_time, 'Time', mail.time),
            _buildDetailRow(Icons.location_on, 'Venue', mail.venue),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(mail.link),
                  icon: const Icon(Icons.edit_note),
                  label: const Text(
                    'Register via Google Form',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
