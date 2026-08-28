import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/widgets/top_notification_overlay.dart';
import '../../../core/services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ─── Change Password Dialog ──────────────────────────────────────────────
  // Verifies current password against FIREBASE AUTH (not local data), then
  // updates Firebase Auth + Firestore + in-memory state simultaneously.
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref, H4Student student) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isUpdating = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: Color(0xFF1B5E20), size: 26),
                SizedBox(width: 10),
                Text('Change Password',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1B5E20))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your current password is verified securely against Firebase.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Current Password — verified against Firebase Auth via re-auth
                  TextField(
                    controller: currentPassController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter your current password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // New Password
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'At least 6 characters',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.key, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm New Password
                  TextField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter your new password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
                child: Text('CANCEL', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isUpdating
                    ? null
                    : () async {
                        final currentPass = currentPassController.text.trim();
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

                        // Client-side validations
                        if (currentPass.isEmpty) {
                          setDialogState(() => errorMessage = 'Enter your current password.');
                          return;
                        }
                        if (newPass.length < 6) {
                          setDialogState(() => errorMessage = 'New password must be at least 6 characters.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setDialogState(() => errorMessage = 'New passwords do not match.');
                          return;
                        }
                        if (newPass == currentPass) {
                          setDialogState(() => errorMessage = 'New password must be different from current.');
                          return;
                        }

                        setDialogState(() { isUpdating = true; errorMessage = null; });

                        try {
                          String studentEmail = '';
                          if (student.email != null && student.email!.trim().isNotEmpty) {
                            studentEmail = student.email!.trim().toLowerCase();
                          } else {
                            studentEmail = '${student.registrationNo}@smartmess.edu';
                          }

                          User? firebaseUser = FirebaseAuth.instance.currentUser;
                          if (firebaseUser == null) {
                            // If current user session is detached, authenticate with currentPass
                            final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: studentEmail,
                              password: currentPass,
                            );
                            firebaseUser = userCred.user;
                          } else {
                            // STEP 1: Re-authenticate with Firebase Auth using original password.
                            // Validates currentPass strictly against Firebase Authentication.
                            final credential = EmailAuthProvider.credential(
                              email: firebaseUser.email ?? studentEmail,
                              password: currentPass,
                            );
                            await firebaseUser.reauthenticateWithCredential(credential);
                          }

                          if (firebaseUser == null) {
                            setDialogState(() { isUpdating = false; errorMessage = 'Authentication failed. Please try again.'; });
                            return;
                          }

                          // STEP 2: Update password in Firebase Auth (cloud)
                          await firebaseUser.updatePassword(newPass);

                          // STEP 3: Sync to in-memory roster and Riverpod state immediately
                          H4StudentDirectory.updateStudentPassword(student.registrationNo, newPass);
                          final updatedStudent = student.copyWith(password: newPass);
                          ref.read(currentStudentProvider.notifier).state = updatedStudent;

                          // STEP 4: Close dialog immediately without any spinning delay
                          Navigator.of(dialogContext, rootNavigator: true).pop();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(child: Text('Password updated successfully across all systems!')),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }

                          // STEP 5: Background non-blocking sync to Firestore database
                          FirebaseFirestore.instance
                              .collection('students')
                              .doc(student.registrationNo)
                              .set({
                            'studentId': student.registrationNo,
                            'name': student.name,
                            'email': firebaseUser.email ?? studentEmail,
                            'password': newPass,
                            'updatedAt': DateTime.now().toIso8601String(),
                          }, SetOptions(merge: true)).catchError((_) {});
                          return;
                        } on FirebaseAuthException catch (e) {
                          String msg;
                          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                            msg = 'Current password is incorrect. Please try again.';
                          } else if (e.code == 'requires-recent-login') {
                            msg = 'Session expired. Please log out and log in again before changing your password.';
                          } else if (e.code == 'weak-password') {
                            msg = 'New password is too weak. Use at least 6 characters.';
                          } else {
                            msg = 'Error: ${e.message}';
                          }
                          setDialogState(() { isUpdating = false; errorMessage = msg; });
                        } catch (e) {
                          setDialogState(() { isUpdating = false; errorMessage = 'An unexpected error occurred. Please try again.'; });
                          debugPrint('[CHANGE-PASSWORD] Unexpected: $e');
                        }
                      },
                child: isUpdating
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    final initials = student.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Avatar Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFE0F2F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF1B5E20),
                  child: Text(initials, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)), textAlign: TextAlign.center),
                const SizedBox(height: 3),
                Text('Roll No: ${student.rollNo} • ${student.branch}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text('Hostel Number 4 Resident (Active)', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details List
          _infoTile(Icons.assignment_ind, 'Registration Number', student.registrationNo),
          _infoTile(Icons.apartment, 'Hostel & Mess', student.hostel),
          _infoTile(Icons.meeting_room, 'Allocated Room', 'Room ${student.roomNo}'),
          _infoTile(Icons.school, 'Branch & Semester', '${student.branch} Engineering • ${student.semester} Semester'),
          _infoTile(Icons.grade, 'Academic Standing', 'CGPA: ${student.cgpa} (Last Semester)'),
          _infoTile(Icons.phone, 'Contact Phone', '+91 ${student.mobile}'),
          
          // Password Tile with Action Button
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock, color: Color(0xFF1B5E20), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Password', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('•••••••• (Secured)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('CHANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showChangePasswordDialog(context, ref, student),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            onPressed: () => AuthService.performLogout(ref, context),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
