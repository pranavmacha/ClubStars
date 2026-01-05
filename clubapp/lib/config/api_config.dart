import 'environment.dart';

/// API configuration for different environments
abstract class ApiConfig {
  static const String baseUrlDev = 'http://localhost:5000';
  static const String baseUrlStaging = 'https://staging-clubstars.onrender.com';
  static const String baseUrlProd = 'https://clubstars.onrender.com';

  static String get baseUrl {
    switch (AppEnvironment.current) {
      case Environment.development:
        return baseUrlDev;
      case Environment.staging:
        return baseUrlStaging;
      case Environment.production:
        return baseUrlProd;
    }
  }

  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}
