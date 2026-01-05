import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';
import '../config/app_strings.dart';
import '../models/club_mail.dart';
import '../utils/app_logger.dart';

/// Service for handling API calls
class ApiService {
  late final Dio _dio;
  late final String _baseUrl;

  ApiService() {
    _baseUrl = ApiConfig.baseUrl;
    _initializeDio();
  }

  /// Initialize Dio with interceptors and configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConfig.apiTimeout,
        receiveTimeout: ApiConfig.apiTimeout,
        sendTimeout: ApiConfig.apiTimeout,
        contentType: 'application/json',
        validateStatus: (status) {
          // Accept all status codes, handle them manually
          return status != null && status < 500;
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(LoggingInterceptor());

    // Add retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        maxRetries: ApiConfig.maxRetries,
        retryDelay: ApiConfig.retryDelay,
      ),
    );
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userEmailKey);
    } catch (e) {
      AppLogger.e('Failed to get user email', e);
      return null;
    }
  }

  /// Store user email
  Future<void> setUserEmail(String email) async {
    if (!_isValidEmail(email)) {
      throw ArgumentError(AppStrings.errorInvalidEmail);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userEmailKey, email.toLowerCase());
      AppLogger.v('User email stored');
    } catch (e) {
      AppLogger.e('Failed to store user email', e);
      rethrow;
    }
  }

  /// Fetch club mails from the API
  Future<List<ClubMail>> fetchClubMails() async {
    try {
      AppLogger.i('Fetching club mails...');
      final email = await getUserEmail();

      final options = Options(
        headers: email != null ? {'user-email': email} : {},
      );

      final response = await _dio.get<List<dynamic>>(
        '/club-mails',
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        final mails = response.data!
            .map((item) => ClubMail.fromJson(item as Map<String, dynamic>))
            .toList();
        AppLogger.i('Fetched ${mails.length} club mails');
        return mails;
      } else {
        throw Exception(AppStrings.errorFailedToLoadMails);
      }
    } on DioException catch (e) {
      AppLogger.e('Network error while fetching club mails', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.e('Error fetching club mails', e);
      throw Exception('Error fetching data: $e');
    }
  }

  /// Sync past mails from user's email account
  Future<int> syncPastMails() async {
    try {
      AppLogger.i('Syncing past mails...');
      final email = await getUserEmail();

      // Increased timeout specifically for sync which can be slow
      final options = Options(
        headers: email != null ? {'user-email': email} : {},
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      );
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google/sync',
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        final syncedCount = response.data!['synced_links'] as int? ?? 0;
        AppLogger.i('Synced $syncedCount mails');
        return syncedCount;
      } else {
        throw Exception(AppStrings.errorFailedToSync);
      }
    } on DioException catch (e) {
      AppLogger.e('Network error while syncing mails', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.e('Error syncing mails', e);
      throw Exception('Error syncing: $e');
    }
  }


  /// Get login URL for OAuth flow
  String get loginUrl => '$_baseUrl/auth/google/login';

  /// Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
  }

  /// Handle Dio errors and convert to user-friendly messages
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Request timeout. Please try again.');
      case DioExceptionType.badResponse:
        return Exception('Server error: ${error.response?.statusCode}');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
        return Exception(AppStrings.errorNetwork);
      default:
        return Exception('An error occurred');
    }
  }
}

/// Logging interceptor for Dio
class LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.v('${options.method} ${options.path}');
    if (options.data != null) {
      AppLogger.v('Request Data: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    AppLogger.v(
      'Response ${response.statusCode}: ${response.requestOptions.path}',
    );
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.e('Request error: ${err.message}', err);
    return handler.next(err);
  }
}

/// Retry interceptor for automatic request retry
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    required this.maxRetries,
    required this.retryDelay,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Initialize retry count if it doesn't exist
    int retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    // Only retry on network errors or server errors (5xx)
    if (_shouldRetry(err) && retryCount < maxRetries) {
      retryCount++;
      err.requestOptions.extra['retryCount'] = retryCount;

      AppLogger.i(
        'Retrying request ($retryCount/$maxRetries): ${err.requestOptions.path}',
      );

      await Future.delayed(retryDelay);

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// Determine if the request should be retried
  bool _shouldRetry(DioException error) {
    // Retry on connection errors
    if (error.type == DioExceptionType.unknown) return true;

    // Retry on timeout
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout)
      return true;

    // Retry on server errors (5xx) but not client errors (4xx)
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500)
      return true;

    return false;
  }
}
