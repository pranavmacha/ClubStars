/// Centralized string constants for the app
abstract class AppStrings {
  // General
  static const String appName = 'ClubStars';
  static const String appVersion = '1.4.0';

  // Login Screen
  static const String loginTitle = 'Club Dashboard';
  static const String loginButtonText = 'Sign in with Google';
  static const String loginSubtitle = 'Discover and manage your favorite clubs';

  // Dashboard Screen
  static const String dashboardTitle = 'Club Dashboard';
  static const String syncTooltip = 'Sync past mails';
  static const String settingsTooltip = 'Settings';
  static const String syncSuccess = 'Synced %s new links!';
  static const String syncFailed = 'Sync failed: %s';
  static const String noMails =
      'No recent club mails found.\nTry syncing your inbox!';
  static const String indexErrorTitle = 'Firestore Index Required';
  static const String indexErrorMessage =
      'This view requires a Firestore Index.\nPlease check your Google Cloud Console to enable the required composite index.';

  // Settings Screen
  static const String settingsTitle = 'Settings';
  static const String signOut = 'Sign Out';
  static const String signOutConfirm = 'Are you sure you want to sign out?';

  // Error Messages
  static const String errorUnexpected = 'An unexpected error occurred';
  static const String errorNetwork = 'Network error. Please try again.';
  static const String errorLogin = 'Login Failed: %s';
  static const String errorInvalidEmail = 'Invalid email format';
  static const String errorNoTokens =
      'Could not retrieve authentication tokens.';
  static const String errorFailedToLoadMails = 'Failed to load club mails';
  static const String errorFailedToSync = 'Failed to sync historical mails';
  static const String errorInitialization = 'Failed to initialize the app';
  static const String errorCheckPresidentStatus =
      'Error checking president status: %s';

  // Loading Messages
  static const String loading = 'Loading...';
  static const String syncing = 'Syncing...';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
}
