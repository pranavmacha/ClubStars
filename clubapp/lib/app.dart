import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/club_mails_screen.dart';
import 'screens/form_webview_screen.dart';
import 'screens/president_portal_screen.dart';
import 'screens/admin_console_screen.dart';

class ClubStarsApp extends StatelessWidget {
  const ClubStarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubStars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        PermissionScreen.route: (_) => const PermissionScreen(),
        DashboardScreen.route: (_) => const DashboardScreen(),
        SettingsScreen.route: (_) => const SettingsScreen(),
        ClubMailsScreen.route: (_) => const ClubMailsScreen(),
        FormWebViewScreen.route: (context) {
          final url = ModalRoute.of(context)!.settings.arguments as String;
          return FormWebViewScreen(url: url);
        },
        PresidentPortalScreen.route: (context) {
          final data = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PresidentPortalScreen(clubData: data);
        },
        AdminConsoleScreen.route: (_) => const AdminConsoleScreen(),
      },
      initialRoute: SplashScreen.route,
    );
  }
}
