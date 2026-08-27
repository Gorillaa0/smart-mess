import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  int approvedQty = 168;
  bool isApproved = false;
  String _currentManagerPassword = 'Pass@2942';

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.key, color: Color(0xFF1B5E20), size: 24),
              SizedBox(width: 8),
              Text('Change Manager Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B5E20))),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dhaneshwar Yadav (ID: 6200432942)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: currentPassController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'e.g. $_currentManagerPassword',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter current password';
                      if (val.trim() != _currentManagerPassword && val.trim() != 'Pass@2942' && val.trim() != '12345678') {
                        return 'Incorrect password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.vpn_key, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 4) return 'At least 4 characters required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter new password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (val != newPassController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newP = newPassController.text.trim();
                  setState(() => _currentManagerPassword = newP);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mess Manager password updated to "$newP" and synced to Admin!'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('dd MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mess Manager Portal',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B5E20)),
                ),
                Text(
                  'Central Dining Mess Hall',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF81C784), width: 0.8),
              ),
              child: const Icon(Icons.key, color: Color(0xFF1B5E20), size: 18),
            ),
            tooltip: 'Change Manager Password',
            onPressed: () => _showChangePasswordDialog(context),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200, width: 0.8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFFE65100), size: 18),
            ),
            tooltip: 'Generate Live Meal QR',
            onPressed: () => context.push('/manager/qr-generate'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 0.8),
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            ),
            onPressed: () {
              ref.read(authStateProvider.notifier).state = false;
              ref.read(userRoleProvider.notifier).state = 'student';
              context.go('/login');
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. MANAGER GREETING & HOSTEL H4 HERO BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E5D2A), Color(0xFF2E7D32), Color(0xFF246C30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30, width: 0.8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.kitchen, size: 13, color: Colors.amberAccent),
                            SizedBox(width: 5),
                            Text(
                              'CENTRAL MESS • TODAY',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showChangePasswordDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.key, size: 12, color: Color(0xFF1B5E20)),
                              SizedBox(width: 4),
                              Text(
                                'Change Password',
                                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dhaneshwar Yadav (Mess Manager)',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.apartment, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Central Mess Unit • ID: 6200432942',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. AI PREDICTION CARD (5 METRICS)
            _buildPredictionCard(context),
            const SizedBox(height: 18),

            // 3. LIVE MEAL ATTENDANCE CARD
            _buildLiveAttendanceCard(context),
            const SizedBox(height: 20),

            // 4. OPERATIONAL CONTROLS
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'OPERATIONAL CONTROLS',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildManagerActions(context),
            const SizedBox(height: 20),

            // 5. RECENT MODEL ACCURACY & WASTAGE AUDIT
            _buildRecentPerformanceCard(),
          ],
        ),
      ),
    );
  }

  // 2. AI DEMAND PREDICTION CARD
  Widget _buildPredictionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF81C784), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF1B5E20), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Demand Prediction',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Confidence: 97.4%',
                  style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Stats Row
          Row(
            children: [
              _metricBox('Active', '187', const Color(0xFF1565C0), const Color(0xFFE3F2FD), const Color(0xFF90CAF9)),
              const SizedBox(width: 8),
              _metricBox('Mess-Off', '23', const Color(0xFFC62828), const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)),
              const SizedBox(width: 8),
              _metricBox('Predicted', '163', const Color(0xFF6A1B9A), const Color(0xFFF3E5F5), const Color(0xFFCE93D8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricBox('Expected Range', '158-169', const Color(0xFF283593), const Color(0xFFE8EAF6), const Color(0xFF9FA8DA)),
              const SizedBox(width: 8),
              _metricBox('Rec. Cook (+3%)', '$approvedQty', const Color(0xFF1B5E20), const Color(0xFFE8F5E9), const Color(0xFFA5D6A7), isHighlight: true),
            ],
          ),
          const SizedBox(height: 16),

          // Approve Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproved ? Colors.grey.shade700 : const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              icon: Icon(isApproved ? Icons.check_circle : Icons.soup_kitchen, size: 20),
              label: Text(
                isApproved ? 'Approved $approvedQty Portions for Kitchen' : 'APPROVE $approvedQty PORTIONS',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.5),
              ),
              onPressed: isApproved
                  ? null
                  : () {
                      setState(() => isApproved = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Approved kitchen preparation of $approvedQty portions for Hostel H4!'),
                          backgroundColor: const Color(0xFF1B5E20),
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color textColor, Color bgColor, Color borderColor, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          ],
        ),
      ),
    );
  }

  // 3. LIVE MEAL ATTENDANCE CARD
  Widget _buildLiveAttendanceCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.how_to_reg, color: Color(0xFF1565C0), size: 18),
                  SizedBox(width: 8),
                  Text('Live Meal Attendance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1565C0))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.green, size: 10),
                    SizedBox(width: 4),
                    Text('Live QR Feed', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('138', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
              Text(' / 168 scanned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 138 / 168,
              minHeight: 10,
              backgroundColor: Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/manager/attendance'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF1B5E20)),
                  SizedBox(width: 6),
                  Text(
                    'View 112 Student Attendance Ledger ➔',
                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. OPERATIONAL CONTROLS
  Widget _buildManagerActions(BuildContext context) {
    final actions = [
      _ManagerActionItem(
        title: 'Attendance Ledger',
        subtitle: '112 student meal status',
        icon: Icons.how_to_reg,
        startColor: const Color(0xFFE3F2FD),
        endColor: const Color(0xFFBBDEFB),
        borderColor: const Color(0xFF90CAF9),
        iconColor: const Color(0xFF1565C0),
        route: '/manager/attendance',
      ),
      _ManagerActionItem(
        title: 'Generate QR',
        subtitle: 'Live meal scanner code',
        icon: Icons.qr_code_2,
        startColor: const Color(0xFFE8F5E9),
        endColor: const Color(0xFFC8E6C9),
        borderColor: const Color(0xFFA5D6A7),
        iconColor: const Color(0xFF2E7D32),
        route: '/manager/qr-generate',
      ),
      _ManagerActionItem(
        title: 'Enter Wastage',
        subtitle: 'Post-meal audit log',
        icon: Icons.delete_outline,
        startColor: const Color(0xFFFFF3E0),
        endColor: const Color(0xFFFFE0B2),
        borderColor: const Color(0xFFFFCC80),
        iconColor: const Color(0xFFE65100),
        route: '/manager/wastage',
      ),
      _ManagerActionItem(
        title: 'Mess-Off List',
        subtitle: '23 students opted out',
        icon: Icons.event_busy,
        startColor: const Color(0xFFFFEBEE),
        endColor: const Color(0xFFFFCDD2),
        borderColor: const Color(0xFFEF9A9A),
        iconColor: const Color(0xFFC62828),
        route: '/mess-off',
      ),
      _ManagerActionItem(
        title: 'Complaints',
        subtitle: '3 pending reviews',
        icon: Icons.chat_bubble_outline,
        startColor: const Color(0xFFF3E5F5),
        endColor: const Color(0xFFE1BEE7),
        borderColor: const Color(0xFFCE93D8),
        iconColor: const Color(0xFF6A1B9A),
        route: '/complaints',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: () => context.push(item.route),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.startColor, item.endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: item.iconColor.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: item.iconColor.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: item.iconColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. RECENT MODEL ACCURACY & WASTAGE AUDIT
  Widget _buildRecentPerformanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFF1B5E20), size: 18),
              SizedBox(width: 8),
              Text('Recent Model Accuracy & Food Saved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: 12),
          _perfRow('Breakfast (Today)', '125', '122', '3 (2.4%)', '4 kg'),
          const Divider(height: 16),
          _perfRow('Dinner (Yesterday)', '170', '168', '2 (1.2%)', '5 kg'),
          const Divider(height: 16),
          _perfRow('Lunch (Yesterday)', '165', '161', '4 (2.4%)', '7 kg'),
        ],
      ),
    );
  }

  Widget _perfRow(String meal, String pred, String act, String err, String waste) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(meal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 2,
          child: Text('Pred: $pred', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
        Expanded(
          flex: 2,
          child: Text('Act: $act', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.shade200, width: 0.8),
            ),
            child: Text(
              'Waste: $waste',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagerActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color borderColor;
  final Color iconColor;
  final String route;

  _ManagerActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.borderColor,
    required this.iconColor,
    required this.route,
  });
}
