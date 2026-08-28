import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../widgets/top_notification_overlay.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(FirebaseAuth.instance));
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithStudentId(String studentId, String password) async {
    final email = '$studentId@smartmess.edu';
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String studentId) async {
    final email = '$studentId@smartmess.edu';
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Global bulletproof logout that wipes local browser storage, Riverpod state, and Firebase session
  static Future<void> performLogout(WidgetRef ref, BuildContext context) async {
    TopNotificationOverlay.hide();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('logged_role');
      await prefs.remove('logged_student_reg');
      await prefs.clear();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    ref.read(authStateProvider.notifier).state = false;
    ref.read(userRoleProvider.notifier).state = 'student';

    if (context.mounted) {
      context.go('/login');
    }
  }
}
