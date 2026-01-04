import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import '../services/profile_service.dart';
import '../services/club_service.dart';
import 'president_portal_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _shareApp() {
    Share.share(
      'Check out ClubStars! The ultimate app to manage VIT-AP club events effortlessly. 🚀✨',
      subject: 'Elevating Campus Life',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Auto-fill Profile'),
              subtitle: const Text('Pre-fill forms with your details'),
              onTap: () => _showProfileDialog(context),
            ),
            const Divider(),
            FutureBuilder<Map<String, dynamic>?>(
              future: ClubService().getClubForPresident(FirebaseAuth.instance.currentUser?.email ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.deepPurple),
                        title: const Text('President Portal'),
                        subtitle: const Text('Manage club banners and assets'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          PresidentPortalScreen.route,
                          arguments: snapshot.data,
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share with Friends'),
              subtitle: const Text('Spread the word about ClubStars'),
              onTap: _shareApp,
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              subtitle: Text('ClubStars v1.5.0'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) async {
    final profileService = ProfileService();
    final profile = await profileService.getProfile();

    final nameController = TextEditingController(text: profile['name']);
    final regController = TextEditingController(text: profile['reg_no']);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-fill Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
              ),
            ),
            TextField(
              controller: regController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await profileService.saveProfile(
                name: nameController.text,
                regNo: regController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
