/// Environment configuration for the app
enum Environment { development, staging, production }

/// AppEnvironment configuration
class AppEnvironment {
  static const Environment current = Environment.production;

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static bool get enableDebugLogging => isDevelopment || isStaging;
}
