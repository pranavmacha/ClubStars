import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/club_service.dart';
import '../services/profile_service.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Initialize all services in the service locator
void setupServiceLocator() {
  // Register singletons
  getIt.registerSingleton<ApiService>(ApiService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<ClubService>(ClubService());
  getIt.registerSingleton<ProfileService>(ProfileService());
}

/// Get instances from service locator
T getService<T extends Object>() => getIt<T>();
