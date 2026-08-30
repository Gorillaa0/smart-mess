import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/h4_students_data.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'student'; // 'student' or 'manager'

  @override
  void initState() {
    super.initState();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_selectedRole == 'student') {
      final rawQuery = _idController.text.trim();
      final query = rawQuery.toLowerCase();
      final password = _passwordController.text.trim();

      // Step 1: Look up student in local static directory instantly (0ms)
      H4Student? student = H4StudentDirectory.findByRegistrationOrRoll(query) ??
          H4StudentDirectory.students.cast<H4Student?>().firstWhere(
            (s) => (s?.email ?? '').toLowerCase() == query,
            orElse: () => null,
          );

      // Determine real-time Firebase Auth target email instantly (0ms)
      String targetEmail = '';
      if (student != null && student.email != null && student.email!.trim().isNotEmpty) {
        targetEmail = student.email!.trim().toLowerCase();
      } else if (query.contains('@')) {
        targetEmail = query;
      } else if (student != null) {
        targetEmail = '${student.registrationNo}@smartmess.edu';
      } else {
        targetEmail = '${rawQuery}@smartmess.edu';
      }

      // Step 2: Instant Direct Firebase Authentication
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        );

        // Verification Succeeded! Firebase Auth verified the credentials
        if (userCredential.user != null) {
          setState(() => _isLoading = false);

          student ??= H4Student(
            slNo: 999,
            name: rawQuery,
            rollNo: rawQuery,
            mobile: '9876543210',
            email: targetEmail,
            branch: 'CSE',
            registrationNo: rawQuery,
            semester: '6th',
            cgpa: 8.0,
            roomNo: '101',
            password: password,
          );

          H4StudentDirectory.updateStudentPassword(student.registrationNo, password);
          final updatedStudent = student.copyWith(password: password);
          ref.read(currentStudentProvider.notifier).state = updatedStudent;

          ref.read(userRoleProvider.notifier).state = 'student';
          ref.read(authStateProvider.notifier).state = true;

          // Save session to local storage
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('logged_role', 'student');
            await prefs.setString('logged_student_reg', student.registrationNo);
          } catch (_) {}

          // Non-blocking background sync to Firestore
          FirebaseFirestore.instance
              .collection('students')
              .doc(student.registrationNo)
              .set({
            'studentId': student.registrationNo,
            'name': student.name,
            'email': targetEmail,
            'password': password,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true)).catchError((_) {});

          return;
        }
      } on FirebaseAuthException catch (authErr) {
        debugPrint('[FIREBASE AUTH] Sign-in error: ${authErr.code} - ${authErr.message}');

        // First-time provision: if account not yet created on Firebase Auth
        if (authErr.code == 'user-not-found') {
          final isInitialMatch = (student != null && H4StudentDirectory.verifyPassword(student, password));
          if (isInitialMatch) {
            try {
              final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: targetEmail,
                password: password,
              );
              if (newCred.user != null) {
                setState(() => _isLoading = false);
                H4StudentDirectory.updateStudentPassword(student.registrationNo, password);
                final updatedStudent = student.copyWith(password: password);
                ref.read(currentStudentProvider.notifier).state = updatedStudent;

                ref.read(userRoleProvider.notifier).state = 'student';
                ref.read(authStateProvider.notifier).state = true;

                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_logged_in', true);
                  await prefs.setString('logged_role', 'student');
                  await prefs.setString('logged_student_reg', student.registrationNo);
                } catch (_) {}

                return;
              }
            } catch (createErr) {
              debugPrint('[FIREBASE AUTH] Auto-provision error: $createErr');
            }
          }
        }
      } catch (e) {
        debugPrint('[FIREBASE AUTH] Unexpected error: $e');
      }

      // Authentication Failed - Strictly verified by Firebase Authentication
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Email/ID or Password. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // Manager login
      setState(() => _isLoading = false);
      ref.read(userRoleProvider.notifier).state = 'manager';
      ref.read(authStateProvider.notifier).state = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('logged_role', 'manager');
      } catch (_) {}
    }
  }

  void _showForgotPasswordModal() {
    final emailController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bSheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_reset, color: Color(0xFF1B5E20), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Forgot Password',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(bSheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your registered email address below to receive a password reset link.',
                style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your registered email address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.mail_outline, size: 18),
                  label: Text(
                    isSubmitting ? 'SENDING LINK...' : 'SEND RESET LINK',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final inputEmail = emailController.text.trim().toLowerCase();
                          if (inputEmail.isEmpty || !inputEmail.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Your email ID is not registered.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);

                          // Check if email exists in roster, userChangedEmails, or student database
                          final bool isRegistered = H4StudentDirectory.students.any(
                                (s) => (s.email ?? '').trim().toLowerCase() == inputEmail,
                              ) ||
                              H4StudentDirectory.userChangedEmails.values.any((e) => e.trim().toLowerCase() == inputEmail) ||
                              inputEmail == 'pawankr0745@gmail.com' ||
                              inputEmail == 'manager@smartmess.edu' ||
                              inputEmail == 'admin@smartmess.edu' ||
                              inputEmail.endsWith('@smartmess.edu');

                          if (!isRegistered) {
                            setSheetState(() => isSubmitting = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Your email ID is not registered.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          try {
                            // Send real password reset email via Firebase Auth
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: inputEmail);
                          } on FirebaseAuthException catch (authErr) {
                            if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
                              // Auto-provision user account on Firebase Auth if not created yet
                              try {
                                final tempPass = 'Pass@${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';
                                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                  email: inputEmail,
                                  password: tempPass,
                                );
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: inputEmail);
                              } catch (createErr) {
                                debugPrint('[AUTH] Auto-provisioning error: $createErr');
                              }
                            } else {
                              debugPrint('[AUTH] Reset email exception: ${authErr.message}');
                            }
                          } catch (err) {
                            debugPrint('[AUTH] Reset email error: $err');
                          }

                          if (!context.mounted) return;
                          Navigator.pop(bSheetCtx);

                          showDialog(
                            context: context,
                            builder: (dlgCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                                  SizedBox(width: 8),
                                  Text('Reset Link Sent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              content: Text(
                                'A password reset link has been dispatched to $inputEmail.\n\nPlease check your inbox and Spam folder. Click the link inside the email to set your new password.',
                                style: const TextStyle(fontSize: 12.5, height: 1.3),
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(dlgCtx),
                                  child: const Text('OKAY'),
                                ),
                              ],
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _selectedRole == 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Hostel Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant, size: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Institutional Header
                  const Text(
                    'Smart Mess • Institutional Dining Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Smart Mess Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isStudent ? '112 Registered H4 Students Database' : 'Hostel No. 4 Kitchen Operations & QR Counter',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Role Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'student';
                                _idController.clear();
                                _passwordController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isStudent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isStudent
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school, size: 18, color: isStudent ? const Color(0xFF1B5E20) : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Student Login',
                                    style: TextStyle(
                                      fontWeight: isStudent ? FontWeight.w800 : FontWeight.w500,
                                      color: isStudent ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'manager';
                                _idController.clear();
                                _passwordController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isStudent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isStudent
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.soup_kitchen, size: 18, color: !isStudent ? const Color(0xFF1B5E20) : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mess Manager',
                                    style: TextStyle(
                                      fontWeight: !isStudent ? FontWeight.w800 : FontWeight.w500,
                                      color: !isStudent ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Credentials Input Form
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStudent ? 'REGISTRATION NO. / ROLL NO.' : 'MANAGER EMAIL / ID',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: 'Enter ID',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            prefixIcon: Icon(isStudent ? Icons.badge_outlined : Icons.email_outlined, color: const Color(0xFF2E7D32)),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (value) => value!.isEmpty ? (isStudent ? 'Enter your Registration No. / Roll No.' : 'Enter Manager ID') : null,
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'PASSWORD',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (value) => value!.isEmpty ? 'Enter your Password' : null,
                        ),
                        const SizedBox(height: 18),

                        // Login Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    isStudent ? 'ACCESS STUDENT DASHBOARD' : 'LOGIN TO MANAGER CONSOLE',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password Button
                        Center(
                          child: TextButton(
                            onPressed: _showForgotPasswordModal,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
