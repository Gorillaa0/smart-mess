import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/h4_students_data.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: '23105108019'); // Default: Ayush Kumar Singh (Reg No)
  final _passwordController = TextEditingController(text: 'Pass@8019');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'student'; // 'student' or 'manager'

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_selectedRole == 'student') {
        final query = _idController.text.trim();
        final student = H4StudentDirectory.findByRegistrationOrRoll(query);

        if (student == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration No. / Roll No. not found in Hostel Number 4 record.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        final isValidPassword = H4StudentDirectory.verifyPassword(student, _passwordController.text.trim());
        if (!isValidPassword) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Incorrect password! Default password for ${student.name} is ${student.password}'),
                backgroundColor: Colors.orange.shade800,
              ),
            );
          }
          return;
        }

        ref.read(currentStudentProvider.notifier).state = student;
        ref.read(userRoleProvider.notifier).state = 'student';
        ref.read(authStateProvider.notifier).state = true;
      } else {
        // Manager login
        ref.read(userRoleProvider.notifier).state = 'manager';
        ref.read(authStateProvider.notifier).state = true;
      }
    }
  }

  void _quickSelectStudent(H4Student student) {
    setState(() {
      _selectedRole = 'student';
      _idController.text = student.registrationNo;
      _passwordController.text = student.password;
    });
    ref.read(currentStudentProvider.notifier).state = student;
    ref.read(userRoleProvider.notifier).state = 'student';
    ref.read(authStateProvider.notifier).state = true;
  }

  void _showStudentDirectoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _H4DirectoryBottomSheet(),
    );
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
                'Enter your registered email address below and we will send you a link to reset your password.',
                style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. yourname@gmail.com or student@smartmess.edu',
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
                          final email = emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid email address')),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);
                          await Future.delayed(const Duration(milliseconds: 500));

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
                                  Text('Email Sent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              content: Text(
                                'A password reset link has been sent to $email. Please check your inbox and click the link to reset your password.',
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
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
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
                                _idController.text = '23105108019';
                                _passwordController.text = 'Pass@8019';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isStudent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isStudent
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
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
                                _idController.text = '6200432942'; // Dhaneshwar Yadav (Mobile ID)
                                _passwordController.text = 'Pass@2942';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isStudent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isStudent
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
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
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStudent ? 'REGISTRATION NO. / ROLL NO.' : 'MANAGER EMAIL',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: isStudent ? 'e.g. 23105108019 or 23508' : 'manager@smartmess.edu',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            prefixIcon: Icon(isStudent ? Icons.badge_outlined : Icons.email_outlined, color: const Color(0xFF2E7D32)),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (value) => value!.isEmpty ? (isStudent ? 'Enter your Registration No. / Roll No.' : 'Enter Manager Email') : null,
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
                            hintText: isStudent ? 'Enter your confidential unique password' : 'Enter Manager Password',
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
                  const SizedBox(height: 16),

                  // Student Directory & Credentials Lookup Button
                  InkWell(
                    onTap: _showStudentDirectoryModal,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF81C784), width: 1.1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_outlined, color: Color(0xFF1B5E20), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'View 112 H4 Students & Generated Passwords',
                            style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Demo Section
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OR 1-CLICK DEMO LOGIN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2 Quick Demo Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: const BorderSide(color: Color(0xFFA5D6A7)),
                            backgroundColor: const Color(0xFFE8F5E9),
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('Ayush (CSE-1)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          onPressed: () => _quickSelectStudent(H4StudentDirectory.students[0]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                            side: const BorderSide(color: Color(0xFF90CAF9)),
                            backgroundColor: const Color(0xFFE3F2FD),
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('Pintu (CSE-2)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          onPressed: () => _quickSelectStudent(H4StudentDirectory.students[1]),
                        ),
                      ),
                    ],
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

// BOTTOM SHEET MODAL SHOWING ALL 112 H4 STUDENTS WITH SEARCH & AUTO-LOGIN
class _H4DirectoryBottomSheet extends StatefulWidget {
  const _H4DirectoryBottomSheet();

  @override
  State<_H4DirectoryBottomSheet> createState() => _H4DirectoryBottomSheetState();
}

class _H4DirectoryBottomSheetState extends State<_H4DirectoryBottomSheet> {
  String _query = '';
  String _selectedBranch = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = H4StudentDirectory.students.where((s) {
      final matchesQuery = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.registrationNo.contains(_query) ||
          s.rollNo.toLowerCase().contains(_query.toLowerCase());
      final matchesBranch = _selectedBranch == 'All' || s.branch.toLowerCase() == _selectedBranch.toLowerCase();
      return matchesQuery && matchesBranch;
    }).toList();

    return Consumer(
      builder: (context, ref, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hostel Number 4 Student Directory',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                        ),
                        Text(
                          '112 Verified Residents • Click any student to log in',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Roll No. or Registration No...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                    filled: true,
                    fillColor: const Color(0xFFF7FAF7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),

              // Branch Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: ['All', 'CSE', 'ECE', 'EE', 'ME', 'Civil'].map((branch) {
                    final isSelected = _selectedBranch == branch;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(branch, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (val) => setState(() => _selectedBranch = branch),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${s.slNo}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s.branch,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Reg No: ${s.registrationNo} • Roll: ${s.rollNo} • CGPA: ${s.cgpa}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Password: ${s.password} • Room: ${s.roomNo}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ref.read(currentStudentProvider.notifier).state = s;
                              ref.read(userRoleProvider.notifier).state = 'student';
                              ref.read(authStateProvider.notifier).state = true;
                              Navigator.pop(context);
                            },
                            child: const Text('LOGIN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
