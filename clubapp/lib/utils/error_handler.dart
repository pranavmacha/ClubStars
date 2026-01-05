import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import 'app_logger.dart';

/// Unified error handler for the application
class AppErrorHandler {
  /// Get user-friendly error message from various exception types
  static String getMessage(dynamic error) {
    // Firebase Auth Exceptions
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    }

    // Firebase Exceptions
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error.code);
    }

    // Generic exceptions
    if (error is ArgumentError) {
      return error.message ?? AppStrings.errorUnexpected;
    }

    if (error is FormatException) {
      return 'Invalid format: ${error.message}';
    }

    if (error is TimeoutException) {
      return 'Request timeout. Please try again.';
    }

    // Default message
    return error.toString().isEmpty
        ? AppStrings.errorUnexpected
        : error.toString();
  }

  /// Handle and display error in UI
  static void handleError(
    BuildContext context,
    dynamic error, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) {
    AppLogger.e('Error: $title', error);

    final message = getMessage(error);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(label: 'Retry', onPressed: onRetry)
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error dialog
  static void showErrorDialog(
    BuildContext context,
    String title,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message = getMessage(error);
    AppLogger.e('Dialog Error: $title', error);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Get Firebase Auth specific error message
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This login method is not enabled.';
      case 'invalid-email':
        return AppStrings.errorInvalidEmail;
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'account-exists-with-different-credential':
        return 'Account already exists with different credential.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'network-request-failed':
        return AppStrings.errorNetwork;
      default:
        return 'Authentication error: $code';
    }
  }

  /// Get Firebase specific error message
  static String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to access this resource.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'The resource already exists.';
      case 'failed-precondition':
        return 'A required Firestore index is missing. Check Google Cloud Console.';
      case 'aborted':
        return 'The operation was aborted. Please try again.';
      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'unauthenticated':
        return 'Authentication required. Please log in again.';
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';
      default:
        return 'Firebase error: $code';
    }
  }
}
