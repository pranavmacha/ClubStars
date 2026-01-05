import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'utils/service_locator.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    AppLogger.i('Firebase initialized successfully');
  } catch (e) {
    AppLogger.e('Failed to initialize Firebase', e);
  }

  // Setup dependency injection
  try {
    setupServiceLocator();
    AppLogger.i('Service locator initialized successfully');
  } catch (e) {
    AppLogger.e('Failed to initialize service locator', e);
  }

  runApp(const ClubStarsApp());
}
