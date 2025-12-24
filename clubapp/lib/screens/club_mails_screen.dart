import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/club_mail.dart';
import '../services/api_service.dart';

class ClubMailsScreen extends StatefulWidget {
  static const route = '/club-mails';
  const ClubMailsScreen({super.key});

  @override
  State<ClubMailsScreen> createState() => _ClubMailsScreenState();
}

class _ClubMailsScreenState extends State<ClubMailsScreen> {
  late Future<List<ClubMail>> futureMails;
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    futureMails = api.fetchClubMails();
  }

  Future<void> _refresh() async {
    setState(() {
      futureMails = api.fetchClubMails();
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: FutureBuilder<List<ClubMail>>(
        future: futureMails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No club mails found'));
          }

          final mails = snapshot.data!;
          return ListView.builder(
            itemCount: mails.length,
            itemBuilder: (context, index) {
              final mail = mails[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: Text(mail.sender),
                  subtitle: Text(mail.link, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchUrl(mail.link),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
