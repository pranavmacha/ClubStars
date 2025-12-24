import 'package:flutter/material.dart';
import 'permission_screen.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ClubStars')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Connect Gmail to discover club events.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'We only read event-related emails. No emails are stored.',
              style: TextStyle(fontSize: 14),
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Continue (Mock Login)',
              onPressed: () =>
                  Navigator.pushNamed(context, PermissionScreen.route),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
