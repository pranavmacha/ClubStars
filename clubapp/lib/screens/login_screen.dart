import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../config/app_strings.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/service_locator.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  late final ApiService _apiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = getService<AuthService>();
    _apiService = getService<ApiService>();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      AppLogger.i('Starting Google Sign-In from LoginScreen');
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        AppLogger.i('Sign-In was cancelled');
        setState(() => _isLoading = false);
        return;
      }

      final String? email = userCredential.user?.email;
      if (email != null) {
        await _apiService.setUserEmail(email);
        AppLogger.i('User successfully logged in: $email');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.loginSuccess),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, DashboardScreen.route);
        }
      }
    } catch (e) {
      AppLogger.e('Login error', e);
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          title: AppStrings.errorLogin.replaceFirst('%s', e.toString()),
          onRetry: _signInWithGoogle,
        );
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.defaultGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Version tag
              Positioned(
                top: 16,
                right: 16,
                child: Text(
                  'v${AppStrings.appVersion}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Hero(
                        tag: 'logo',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.accentColor.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.stars_rounded,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Glassmorphism Card
                      Container(
                        padding: const EdgeInsets.all(
                          AppConstants.largePadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.largeBorderRadius,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              AppStrings.loginTitle,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 48),
                            if (_isLoading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _signInWithGoogle,
                                  icon: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.png/480px-Google_%22G%22_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.login,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                    ),
                                  ),
                                  label: const Text(
                                    AppStrings.loginButtonText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Syncing campus life securely',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
