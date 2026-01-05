import 'package:flutter/material.dart';

/// Application constants
abstract class AppConstants {
  // Animation durations
  static const Duration logoAnimationDuration = Duration(milliseconds: 1500);
  static const Duration titleAnimationDuration = Duration(milliseconds: 1000);
  static const Duration navigationDelay = Duration(milliseconds: 2800);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double smallPadding = 8.0;

  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 20.0;

  // Colors
  static const Color primaryColor = Color(0xFF302B63);
  static const Color accentColor = Colors.deepPurpleAccent;

  static const LinearGradient defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0C29), // Deep Space Blue
      Color(0xFF302B63), // Royal Purple
      Color(0xFF24243E), // Midnight Blue
    ],
  );

  // Firestore Collections
  static const String clubMailsCollection = 'club_mails';
  static const String usersCollection = 'users';
  static const String clubsCollection = 'clubs';

  // Shared Preferences Keys
  static const String userEmailKey = 'user_email';
  static const String lastSyncKey = 'last_sync_time';

  // Secure Storage Keys
  static const String gmailAccessTokenKey = 'gmail_access_token';
  static const String gmailIdTokenKey = 'gmail_id_token';
  static const String gmailServerAuthCodeKey = 'gmail_server_auth_code';
}
