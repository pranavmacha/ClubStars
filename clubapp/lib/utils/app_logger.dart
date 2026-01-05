import 'package:logger/logger.dart';
import '../config/environment.dart';

/// Centralized logger for the application
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: AppEnvironment.isDevelopment ? Level.verbose : Level.warning,
  );

  /// Log verbose message (only in debug/development)
  static void v(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppEnvironment.enableDebugLogging) {
      _logger.v(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log debug message
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log WTF (What a Terrible Failure) message
  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }
}
