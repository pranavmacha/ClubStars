import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../widgets/primary_button.dart';

class PermissionScreen extends StatelessWidget {
  static const route = '/permissions';
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              title: 'What we scan',
              body: 'Only club/event-related emails using keywords & senders.',
            ),
            _card(
              title: 'What we extract',
              body:
                  'Event name, date/time, venue, registration link, deadline.',
            ),
            _card(
              title: 'What we DO NOT do',
              body: 'No sending emails. No auto-submitting Google Forms.',
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Continue',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                DashboardScreen.route,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required String body}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }
}
