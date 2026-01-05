import 'package:flutter_test/flutter_test.dart';
import 'package:clubapp/config/app_strings.dart';
import 'package:clubapp/config/app_constants.dart';
import 'package:clubapp/config/api_config.dart';
import 'package:clubapp/config/environment.dart';

void main() {
  group('AppStrings', () {
    test('AppStrings has all required string constants', () {
      expect(AppStrings.appName, isNotEmpty);
      expect(AppStrings.appVersion, isNotEmpty);
      expect(AppStrings.loginTitle, isNotEmpty);
      expect(AppStrings.dashboardTitle, isNotEmpty);
      expect(AppStrings.errorUnexpected, isNotEmpty);
    });

    test('AppStrings sync messages contain placeholders', () {
      expect(AppStrings.syncSuccess, contains('%s'));
      expect(AppStrings.errorLogin, contains('%s'));
    });
  });

  group('AppConstants', () {
    test('AppConstants has valid padding values', () {
      expect(AppConstants.defaultPadding, greaterThan(0));
      expect(
        AppConstants.largePadding,
        greaterThan(AppConstants.defaultPadding),
      );
      expect(AppConstants.smallPadding, lessThan(AppConstants.defaultPadding));
    });

    test('AppConstants has valid animation durations', () {
      expect(AppConstants.logoAnimationDuration.inMilliseconds, greaterThan(0));
      expect(
        AppConstants.titleAnimationDuration.inMilliseconds,
        greaterThan(0),
      );
      expect(AppConstants.navigationDelay.inMilliseconds, greaterThan(0));
    });

    test('AppConstants has valid border radius values', () {
      expect(AppConstants.defaultBorderRadius, greaterThan(0));
      expect(
        AppConstants.largeBorderRadius,
        greaterThan(AppConstants.defaultBorderRadius),
      );
    });

    test('AppConstants has valid Firestore collection names', () {
      expect(AppConstants.clubMailsCollection, equals('club_mails'));
      expect(AppConstants.usersCollection, equals('users'));
      expect(AppConstants.clubsCollection, equals('clubs'));
    });

    test('AppConstants has valid storage keys', () {
      expect(AppConstants.userEmailKey, isNotEmpty);
      expect(AppConstants.lastSyncKey, isNotEmpty);
      expect(AppConstants.gmailAccessTokenKey, isNotEmpty);
    });
  });

  group('ApiConfig', () {
    test('ApiConfig has valid timeout duration', () {
      expect(ApiConfig.apiTimeout.inSeconds, greaterThan(0));
    });

    test('ApiConfig has valid retry settings', () {
      expect(ApiConfig.maxRetries, greaterThan(0));
      expect(ApiConfig.retryDelay.inSeconds, greaterThanOrEqualTo(0));
    });

    test('ApiConfig returns production URL in production environment', () {
      expect(ApiConfig.baseUrl, equals(ApiConfig.baseUrlProd));
    });
  });

  group('AppEnvironment', () {
    test('AppEnvironment detects production environment', () {
      expect(AppEnvironment.isProduction, isTrue);
      expect(AppEnvironment.isDevelopment, isFalse);
      expect(AppEnvironment.isStaging, isFalse);
    });

    test('AppEnvironment enables debug logging based on environment', () {
      // In production, debug logging should be disabled
      expect(
        AppEnvironment.enableDebugLogging,
        equals(!AppEnvironment.isProduction),
      );
    });
  });
}
