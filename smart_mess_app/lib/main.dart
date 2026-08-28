import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/constants/h4_students_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore session from local storage only if valid and explicit
  bool isLoggedIn = false;
  String loggedRole = 'student';
  H4Student? loggedStudent;

  try {
    final prefs = await SharedPreferences.getInstance();
    final bool rawLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? role = prefs.getString('logged_role');
    final String? regNo = prefs.getString('logged_student_reg');

    if (rawLoggedIn && role == 'manager') {
      isLoggedIn = true;
      loggedRole = 'manager';
    } else if (rawLoggedIn && regNo != null && regNo.trim().isNotEmpty) {
      loggedStudent = H4StudentDirectory.findByRegistrationOrRoll(regNo.trim());
      isLoggedIn = (loggedStudent != null);
    } else {
      isLoggedIn = false;
    }
  } catch (e) {
    debugPrint('Error restoring saved session: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => isLoggedIn),
        userRoleProvider.overrideWith((ref) => loggedRole),
        if (loggedStudent != null) currentStudentProvider.overrideWith((ref) => loggedStudent!),
      ],
      child: const SmartMessApp(),
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
