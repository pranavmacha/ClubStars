# ClubApp Migration Guide - For Developers

**For:** Developers working on ClubApp  
**Purpose:** Guide for using new architecture patterns  
**Last Updated:** January 5, 2026

---

## 🔧 Quick Start for Developers

### 1. Run flutter pub get to install new dependencies

```bash
flutter pub get
```

### 2. Run tests to verify everything works

```bash
flutter test
```

Expected: All 29 tests pass ✓

---

## 📚 Architecture Overview

### Layer 1: Configuration & Constants
```
lib/config/
├── environment.dart       # Dev/Staging/Prod config
├── api_config.dart       # API endpoints by environment
├── app_strings.dart      # UI strings (localization-ready)
└── app_constants.dart    # App-wide constants
```

### Layer 2: Services
```
lib/services/
├── auth_service.dart      # Authentication (refactored)
├── api_service.dart       # API calls (Dio-based)
├── club_service.dart      # Club operations (logging added)
└── profile_service.dart   # User profile
```

### Layer 3: Models
```
lib/models/
└── club_mail.dart        # Enhanced with null-safety
```

### Layer 4: Utilities
```
lib/utils/
├── service_locator.dart   # Dependency injection
├── app_logger.dart        # Structured logging
└── error_handler.dart     # Error management
```

### Layer 5: UI (Screens & Widgets)
```
lib/screens/
├── splash_screen.dart      # Updated with constants
├── login_screen.dart       # Refactored with services
├── dashboard_screen.dart   # Refactored with services
└── ...
```

---

## 🔐 How to Use the New Security Features

### Accessing Secure Storage

```dart
import 'package:clubapp/services/auth_service.dart';
import 'package:clubapp/utils/service_locator.dart';

// Get auth service from locator
final authService = getService<AuthService>();

// Get stored access token
final token = await authService.getAccessToken();

// Sign out (clears tokens)
await authService.signOut();
```

### API Calls with Validation

```dart
import 'package:clubapp/services/api_service.dart';

final apiService = getService<ApiService>();

try {
  // Email is automatically validated
  await apiService.setUserEmail('user@example.com');
  
  // Network calls have retry logic built-in
  final mails = await apiService.fetchClubMails();
} catch (e) {
  // All errors are properly typed and logged
  print(e);
}
```

---

## 🎯 Error Handling Best Practices

### Using AppErrorHandler

```dart
import 'package:clubapp/utils/error_handler.dart';

// For SnackBar errors
try {
  await operation();
} catch (e) {
  AppErrorHandler.handleError(
    context,
    e,
    title: 'Operation Failed',
    onRetry: () => operation(), // Optional retry
  );
}

// For critical errors (Dialog)
try {
  await criticalOperation();
} catch (e) {
  AppErrorHandler.showErrorDialog(
    context,
    'Critical Error',
    e,
    onRetry: () => criticalOperation(),
  );
}
```

### Without Context

```dart
// Just get the message
final userMessage = AppErrorHandler.getMessage(error);
print(userMessage); // User-friendly error message
```

---

## 📝 Logging Guide

### Using AppLogger

```dart
import 'package:clubapp/utils/app_logger.dart';

// Info level - Always shown
AppLogger.i('User logged in: $email');

// Debug level - Always shown
AppLogger.d('Processing data...');

// Warning level
AppLogger.w('Operation took longer than expected', responseTime);

// Error level - Always shown
AppLogger.e('Failed to sync mails', exception, stackTrace);

// Verbose - Development only
AppLogger.v('Internal state updated');

// WTF (What a Terrible Failure)
AppLogger.wtf('This should never happen!', criticalError);
```

---

## 💉 Dependency Injection Guide

### Registering Services

```dart
// In lib/utils/service_locator.dart
void setupServiceLocator() {
  // Add your new service like this:
  getIt.registerSingleton<YourNewService>(YourNewService());
}
```

### Using Injected Services

```dart
import 'package:clubapp/utils/service_locator.dart';

// In any widget/screen
final authService = getService<AuthService>();
final apiService = getService<ApiService>();

// Services are singletons - same instance everywhere
```

---

## 🎨 Using Centralized Strings

### In Screens

```dart
import 'package:clubapp/config/app_strings.dart';
import 'package:clubapp/config/app_constants.dart';

// ❌ BAD
Text('Sign in with Google')

// ✅ GOOD
Text(AppStrings.loginButtonText)

// ❌ BAD
Padding(padding: EdgeInsets.all(16))

// ✅ GOOD
Padding(padding: EdgeInsets.all(AppConstants.defaultPadding))
```

### Adding New Strings

1. Open `lib/config/app_strings.dart`
2. Add constant to abstract class:
```dart
static const String myNewString = 'My string value';
```
3. Use it in screens
4. When adding localization, update in one place!

---

## 🧪 Writing Tests

### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:clubapp/models/club_mail.dart';

void main() {
  group('ClubMail', () {
    test('fromJson handles null values', () {
      final mail = ClubMail.fromJson({'link': null});
      expect(mail.link, '');
    });
  });
}
```

### Run Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/models/club_mail_test.dart

# With coverage
flutter test --coverage
```

---

## 🔄 Migration Checklist for Existing Code

When updating existing screens/services:

- [ ] Replace hardcoded strings with `AppStrings` constants
- [ ] Replace magic numbers with `AppConstants`
- [ ] Replace `print()` with `AppLogger`
- [ ] Replace try-catch with `AppErrorHandler.handleError()`
- [ ] Get services from `getService<ServiceType>()` not `new`
- [ ] Update API calls to handle validation
- [ ] Add null-checks using new model's safe deserialization
- [ ] Add tests for new functionality

---

## 📱 Environment Configuration

### Switching Environments

**Development:**
```dart
// In lib/config/environment.dart
static const Environment current = Environment.development;
```

**Staging:**
```dart
static const Environment current = Environment.staging;
```

**Production:**
```dart
static const Environment current = Environment.production;
```

### Using Environment

```dart
import 'package:clubapp/config/environment.dart';
import 'package:clubapp/config/api_config.dart';

if (AppEnvironment.isDevelopment) {
  // Show debug info
}

final url = ApiConfig.baseUrl; // Gets correct URL for environment
```

---

## 🐛 Debugging with Logs

### View Logs in Console

```bash
flutter logs
```

### Filter by Tag

```bash
flutter logs | grep "ClubApp"
```

### Check Firestore

```dart
AppLogger.i('Saving user to Firestore: $email');
// Look in console for this message
```

---

## 🔄 Common Tasks

### Adding a New Service

1. Create `lib/services/my_service.dart`:
```dart
class MyService {
  // Implementation
}
```

2. Register in `lib/utils/service_locator.dart`:
```dart
getIt.registerSingleton<MyService>(MyService());
```

3. Use in screens:
```dart
final myService = getService<MyService>();
```

### Adding a New Config Constant

1. Open `lib/config/app_constants.dart`
2. Add to abstract class:
```dart
static const double myValue = 42.0;
```
3. Use everywhere:
```dart
SizedBox(height: AppConstants.myValue)
```

### Adding New Error Type

1. Open `lib/utils/error_handler.dart`
2. Add case in `getMessage()`:
```dart
if (error is MyCustomException) {
  return error.userMessage;
}
```

### Adding New Log Level

Currently using logger package's levels: v, d, i, w, e, wtf

To add custom handling, extend `AppLogger` class.

---

## ✅ Quality Checklist

Before committing code:

- [ ] No hardcoded strings (use AppStrings)
- [ ] No hardcoded numbers (use AppConstants)
- [ ] No print() statements (use AppLogger)
- [ ] All errors handled with AppErrorHandler
- [ ] Services get from getService<>()
- [ ] Models use safe deserialization
- [ ] Email validated before saving
- [ ] Tests written for critical logic
- [ ] No warnings in flutter analyze

---

## 📖 Additional Resources

### Key Files to Study

1. **Security:** `lib/services/auth_service.dart`
2. **API:** `lib/services/api_service.dart`
3. **Error Handling:** `lib/utils/error_handler.dart`
4. **Logging:** `lib/utils/app_logger.dart`
5. **Config:** `lib/config/*.dart`

### External Links

- [Dio Documentation](https://pub.dev/packages/dio)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Logger Package](https://pub.dev/packages/logger)

---

## 🆘 Troubleshooting

### Tests Failing?
```bash
flutter clean
flutter pub get
flutter test
```

### Services Not Found?
- Ensure `setupServiceLocator()` is called in `main()`
- Check service is registered in `service_locator.dart`

### Logs Not Showing?
- Check if running in debug/development mode
- Verbose logs only show in development environment

### Null Safety Warnings?
- Update models to use proper null-coalescing
- Check ClubMail model for pattern

---

## 🎓 Learning Path

**Week 1:**
- Read this guide
- Study the config system
- Understand error handling

**Week 2:**
- Study services (Auth, API)
- Practice dependency injection
- Write tests

**Week 3:**
- Apply patterns to new features
- Review logging best practices
- Optimize for performance

---

**Questions?** Check the code comments and test files for examples!
