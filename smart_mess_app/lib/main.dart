import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Always launch runApp immediately so the UI is never blocked or left blank
  runApp(
    const ProviderScope(
      child: SmartMessApp(),
    ),
  );

  // Initialize Firebase in background safely
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    debugPrint('Firebase initialization error: $e');
    return Firebase.app();
  });
}

