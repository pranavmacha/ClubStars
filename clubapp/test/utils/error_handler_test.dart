import 'package:flutter_test/flutter_test.dart';
import 'package:clubapp/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('AppErrorHandler', () {
    test(
      'getMessage returns Firebase Auth error message for user-not-found',
      () {
        final error = FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'No account found with this email.');
      },
    );

    test(
      'getMessage returns Firebase Auth error message for wrong-password',
      () {
        final error = FirebaseAuthException(
          code: 'wrong-password',
          message: 'Password incorrect',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'Incorrect password.');
      },
    );

    test(
      'getMessage returns Firebase Auth error message for too-many-requests',
      () {
        final error = FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many attempts',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'Too many login attempts. Please try again later.');
      },
    );

    test(
      'getMessage returns Firebase Auth error message for invalid-email',
      () {
        final error = FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'Invalid email format');
      },
    );

    test(
      'getMessage returns Firebase Auth error message for email-already-in-use',
      () {
        final error = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email in use',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'This email is already in use.');
      },
    );

    test(
      'getMessage returns Firebase Auth error message for network-request-failed',
      () {
        final error = FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        );

        final message = AppErrorHandler.getMessage(error);

        expect(message, 'Network error. Please try again.');
      },
    );

    test('getMessage handles ArgumentError', () {
      final error = ArgumentError('Invalid argument');

      final message = AppErrorHandler.getMessage(error);

      expect(message, 'Invalid argument');
    });

    test('getMessage handles FormatException', () {
      final error = FormatException('Invalid format', 'bad data');

      final message = AppErrorHandler.getMessage(error);

      expect(message, contains('Invalid format'));
    });

    test('getMessage returns default message for unknown exception', () {
      final message = AppErrorHandler.getMessage(Exception('Unknown error'));

      expect(message, contains('Unknown error'));
    });

    test('getMessage returns generic error for null exception', () {
      final message = AppErrorHandler.getMessage(Exception());

      expect(message, isNotEmpty);
    });
  });
}
