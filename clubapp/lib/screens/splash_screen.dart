import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Constants for animation durations
  static const Duration _logoAnimationDuration = Duration(milliseconds: 1500);
  static const Duration _titleAnimationDuration = Duration(milliseconds: 1000);
  static const Duration _navigationDelay = Duration(milliseconds: 2800);
  static const Duration _authTimeout = Duration(seconds: 10);
  
  late bool _hasError;

  @override
  void initState() {
    super.initState();
    _hasError = false;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add timeout to Firebase auth check
      final user = FirebaseAuth.instance.currentUser;
      
      Future.delayed(_navigationDelay, () {
        if (!mounted) return;
        
        if (user != null) {
          Navigator.pushReplacementNamed(context, DashboardScreen.route);
        } else {
          Navigator.pushReplacementNamed(context, LoginScreen.route);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _retry() async {
    setState(() => _hasError = false);
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    // Build UI
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Unable to Load',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to initialize the app',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29), // Deep Space Blue
              Color(0xFF302B63), // Royal Purple
              Color(0xFF24243E), // Midnight Blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle glowing effect background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.15),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: _logoAnimationDuration,
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 160,
                          width: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 160,
                              height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.deepPurpleAccent,
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Title with fade-in
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: _titleAnimationDuration,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        const Text(
                          'ClubStars',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ELEVATING CAMPUS LIFE',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[200],
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Subtle loading indicator
                  SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
