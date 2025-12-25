import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. Trigger the Google Authentication flow with Gmail READ-ONLY scope
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/gmail.readonly',
        ],
      ).signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final String? email = userCredential.user?.email;

      if (email != null) {
        // 5. Store Gmail credentials for the Cloud Function to use
        // In a real app, you should handle token refresh logic here
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email.toLowerCase())
            .set({
              'email': email,
              'gmail_token': jsonEncode({
                'access_token': googleAuth.accessToken,
                'id_token': googleAuth.idToken,
                // Note: Refresh token requires specific setup with google_sign_in
              }),
              'last_login': FieldValue.serverTimestamp(),
            });

        // 6. Store email locally for legacy components
        await _apiService.setUserEmail(email);

        if (mounted) {
          // 7. Navigate to dashboard
          Navigator.pushReplacementNamed(context, DashboardScreen.route);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ClubStars Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 32),
            const Text(
              'Welcome to ClubStars',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in with your VIT-AP email to manage your club events effortlessly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.login),
                ),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'Sync your club activities efficiently.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
