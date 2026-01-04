import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import '../services/profile_service.dart';

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
              subtitle: Text('ClubStars v1.3.0'),
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
    final phoneController = TextEditingController(text: profile['phone']);
    final branchController = TextEditingController(text: profile['branch']);
    final whatsappController = TextEditingController(text: profile['whatsapp']);

    String? selectedYear = profile['year']!.isEmpty ? null : profile['year'];
    String? selectedGender = profile['gender']!.isEmpty ? null : profile['gender'];
    String? selectedHostel = profile['hostel']!.isEmpty ? null : profile['hostel'];

    final years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', 'Alumni'];
    final genders = ['Male', 'Female', 'Other'];
    final hostelStatuses = ['Hosteller', 'Day Scholar'];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Auto-fill Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: regController,
                  decoration: const InputDecoration(labelText: 'Registration Number'),
                ),
                TextField(
                  controller: branchController,
                  decoration: const InputDecoration(labelText: 'Branch/Program'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (val) => setState(() => selectedYear = val),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => selectedGender = val),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedHostel,
                  decoration: const InputDecoration(labelText: 'Hostel Status'),
                  items: hostelStatuses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  onChanged: (val) => setState(() => selectedHostel = val),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: whatsappController,
                  decoration: const InputDecoration(labelText: 'WhatsApp Number (Optional)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
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
                  phone: phoneController.text,
                  branch: branchController.text,
                  year: selectedYear,
                  gender: selectedGender,
                  hostel: selectedHostel,
                  whatsapp: whatsappController.text,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
