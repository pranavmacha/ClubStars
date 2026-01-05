import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_constants.dart';
import '../config/app_strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/club_service.dart';
import '../models/club_mail.dart';
import '../utils/service_locator.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'event_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const route = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiService _apiService;
  late final ClubService _clubService;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _apiService = getService<ApiService>();
    _clubService = getService<ClubService>();
    AppLogger.i('Dashboard screen initialized');
  }

  Future<void> _handleSync() async {
    AppLogger.i('Starting sync operation');
    setState(() => _isSyncing = true);
    try {
      final count = await _apiService.syncPastMails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.syncSuccess.replaceFirst('%s', count.toString()),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      AppLogger.i('Sync completed: $count new links');
    } catch (e) {
      AppLogger.e('Sync failed', e);
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          title: 'Sync Error',
          onRetry: _handleSync,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text(AppStrings.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = getService<AuthService>();
        await authService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      } catch (e) {
        AppLogger.e('Sign out error', e);
        if (mounted) {
          AppErrorHandler.handleError(context, e, title: 'Sign Out Error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: AppStrings.syncTooltip,
            onPressed: _isSyncing ? null : _handleSync,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppStrings.settingsTooltip,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: user?.email == null
          ? const Center(child: Text('User not authenticated'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.clubMailsCollection)
                  .where('recipient', isEqualTo: user?.email)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  if (error.contains('failed-precondition') ||
                      error.contains('index')) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              AppStrings.indexErrorTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              AppStrings.indexErrorMessage,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noMails,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppConstants.smallPadding),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final mail = ClubMail.fromJson(data);

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(mail: mail),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            // Banner Section
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _clubService.getClubsStream(),
                              builder: (context, snapshot) {
                                String? bannerUrl = mail.bannerUrl;

                                if (bannerUrl == null && snapshot.hasData) {
                                  final titleLower = mail.title.toLowerCase();
                                  for (final club in snapshot.data!) {
                                    final keywords = List<String>.from(
                                      club['keywords'] ?? [],
                                    );
                                    if (keywords.any(
                                      (k) =>
                                          titleLower.contains(k.toLowerCase()),
                                    )) {
                                      bannerUrl = club['bannerUrl'];
                                      break;
                                    }
                                  }
                                }

                                return Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    image: bannerUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(bannerUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: bannerUrl == null
                                      ? Center(
                                          child: Icon(
                                            Icons.event_note,
                                            color: Colors.deepPurple
                                                .withOpacity(0.3),
                                            size: 40,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                mail.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      mail.date,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        mail.venue,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
