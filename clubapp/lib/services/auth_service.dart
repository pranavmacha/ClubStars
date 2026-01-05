import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../config/app_strings.dart';
import '../utils/app_logger.dart';

/// Handles all authentication operations
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1084881258640-nf8hbehl14m5p4i39t8nq5dgcen1d4io.apps.googleusercontent.com',
    scopes: [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'openid',
    ],
  );
  static const _secureStorage = FlutterSecureStorage();

  /// Get current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with Google
  /// Throws [FirebaseAuthException] if sign-in fails
  /// Throws [Exception] if token retrieval fails
  Future<UserCredential?> signInWithGoogle() async {
    try {
      AppLogger.i('Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.i('Google Sign-In was cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception(AppStrings.errorNoTokens);
      }

      // Store tokens securely
      await _storeAuthTokens(
        accessToken: accessToken,
        idToken: idToken,
        serverAuthCode: googleUser.serverAuthCode,
      );

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // Store user data in Firestore
      final String? email = userCredential.user?.email;
      if (email != null) {
        await _storeUserData(email, serverAuthCode: googleUser.serverAuthCode);
        AppLogger.i('User signed in successfully: $email');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth Error: ${e.code}', e);
      rethrow;
    } catch (e) {
      AppLogger.e('Google Sign-In failed', e);
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      AppLogger.i('Signing out user...');
      await _clearAuthTokens();
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      AppLogger.i('User signed out successfully');
    } catch (e) {
      AppLogger.e('Sign out failed', e);
      rethrow;
    }
  }

  /// Store authentication tokens securely
  Future<void> _storeAuthTokens({
    required String accessToken,
    required String idToken,
    String? serverAuthCode,
  }) async {
    try {
      await _secureStorage.write(
        key: AppConstants.gmailAccessTokenKey,
        value: accessToken,
      );
      await _secureStorage.write(
        key: AppConstants.gmailIdTokenKey,
        value: idToken,
      );
      if (serverAuthCode != null) {
        await _secureStorage.write(
          key: AppConstants.gmailServerAuthCodeKey,
          value: serverAuthCode,
        );
      }
      AppLogger.v('Auth tokens stored securely');
    } catch (e) {
      AppLogger.e('Failed to store auth tokens', e);
      rethrow;
    }
  }

  /// Retrieve access token from secure storage
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(
        key: AppConstants.gmailAccessTokenKey,
      );
      return token;
    } catch (e) {
      AppLogger.e('Failed to retrieve access token', e);
      return null;
    }
  }

  /// Clear authentication tokens from secure storage
  Future<void> _clearAuthTokens() async {
    try {
      await _secureStorage.delete(key: AppConstants.gmailAccessTokenKey);
      await _secureStorage.delete(key: AppConstants.gmailIdTokenKey);
      await _secureStorage.delete(key: AppConstants.gmailServerAuthCodeKey);
      AppLogger.v('Auth tokens cleared');
    } catch (e) {
      AppLogger.e('Failed to clear auth tokens', e);
    }
  }

  /// Store user data in Firestore
  Future<void> _storeUserData(String email, {String? serverAuthCode}) async {
    try {
      final String emailLower = email.toLowerCase();
      final Map<String, dynamic> data = {
        'email': email,
        'email_lower': emailLower,
        'last_login': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      };

      if (serverAuthCode != null) {
        data['gmail_token'] = {
          'server_auth_code': serverAuthCode,
          'updated_at': FieldValue.serverTimestamp(),
        };
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(emailLower)
          .set(data, SetOptions(merge: true));
      AppLogger.v('User data stored in Firestore');
    } catch (e) {
      AppLogger.e('Failed to store user data in Firestore', e);
      // Don't rethrow - this is not critical for sign-in
    }
  }

  /// Store user email in local preferences
  Future<void> setUserEmail(String email) async {
    if (!_isValidEmail(email)) {
      throw ArgumentError(AppStrings.errorInvalidEmail);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userEmailKey, email.toLowerCase());
      AppLogger.v('User email stored locally');
    } catch (e) {
      AppLogger.e('Failed to store user email', e);
      rethrow;
    }
  }

  /// Get stored user email from local preferences
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userEmailKey);
    } catch (e) {
      AppLogger.e('Failed to retrieve user email', e);
      return null;
    }
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user's email
  String? get currentUserEmail => currentUser?.email;
}
