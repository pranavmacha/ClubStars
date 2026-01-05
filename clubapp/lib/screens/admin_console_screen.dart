import 'package:flutter/material.dart';
import '../services/club_service.dart';

class AdminConsoleScreen extends StatefulWidget {
  static const route = '/admin-console';

  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final ClubService _clubService = ClubService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _clubService.getClubsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final clubs = snapshot.data ?? [];

          return ListView.builder(
            itemCount: clubs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final club = clubs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    club['name'] ?? 'Unknown Club',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Presidents: ${(club['presidents'] as List? ?? []).join(', ')}'),
                      const SizedBox(height: 4),
                      Text('Keywords: ${(club['keywords'] as List? ?? []).join(', ')}'),
                    ],
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.indigo),
                  onTap: () => _showEditClubDialog(context, club),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditClubDialog(BuildContext context, Map<String, dynamic> club) {
    final nameController = TextEditingController(text: club['name']);
    final presidentsController = TextEditingController(
      text: (club['presidents'] as List? ?? []).join(', '),
    );
    final keywordsController = TextEditingController(
      text: (club['keywords'] as List? ?? []).join(', '),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Club',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: presidentsController,
                decoration: const InputDecoration(
                  labelText: 'President Emails (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'Allows these users to access President Portal',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'Used for matching event banners',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final presidents = presidentsController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    final keywords = keywordsController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    await _clubService.updateClubPresidents(club['id'], presidents);
                    await _clubService.updateClubKeywords(club['id'], keywords);

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
