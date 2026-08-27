import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/weekly_menu.dart';
import '../providers/attendance_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool _isProcessing = false;

  void _verifyAndClaimMeal(String mealType) {
    final student = ref.read(currentStudentProvider);
    final attendanceNotifier = ref.read(liveAttendanceProvider.notifier);

    if (attendanceNotifier.hasScanned(student.registrationNo, mealType)) {
      _showAlreadyScannedDialog(student.name, mealType);
      return;
    }

    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      final success = attendanceNotifier.recordScan(student, mealType);
      setState(() => _isProcessing = false);

      if (success) {
        _showSuccessDialog(student.name, student.registrationNo, student.rollNo, student.branch, student.roomNo, mealType);
      }
    });
  }

  void _showSuccessDialog(String name, String regNo, String rollNo, String branch, String roomNo, String mealType) {
    final timeStr = DateFormat('hh:mm:ss a').format(DateTime.now());
    final plateToken = 'H4-${mealType.substring(0, 1).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'MEAL PLATE VERIFIED!',
              style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Hostel Number 4 Kitchen Counter',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Token Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                children: [
                  const Text('PLATE TOKEN ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
                  Text(plateToken, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Details Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _rowItem('Resident Name:', name),
                  _rowItem('Registration No:', regNo),
                  _rowItem('Roll No & Branch:', '$rollNo ($branch)'),
                  _rowItem('Hostel Room:', 'Room $roomNo (H4)'),
                  _rowItem('Meal Type:', mealType.toUpperCase()),
                  _rowItem('Verified Time:', timeStr),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('DONE & ENJOY MEAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlreadyScannedDialog(String name, String mealType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Already Claimed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Student $name has ALREADY scanned and claimed their plate for today\'s $mealType.\n\nDuplicate scans for the same meal session are prevented.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final now = DateTime.now();
    final todayMenu = WeeklyMenuData.getTodayMenu(now);
    final activeMeal = WeeklyMenuData.getActiveMealState(now);
    final activeMealTitle = activeMeal.meal?.nameEnglish ?? 'Lunch';

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Meal QR Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Student Info Pill
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          'Reg: ${student.registrationNo} â€¢ Room ${student.roomNo} (${student.branch})',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Target Scanner Viewport
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 72, color: Colors.greenAccent.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'Align Mess Counter QR',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Scan Trigger Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE MEAL SESSION',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          Text(
                            activeMealTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.radar, size: 12, color: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text('COUNTER LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.qr_code, size: 20),
                      label: Text(
                        _isProcessing ? 'VERIFYING PLATE...' : 'SCAN & VERIFY $activeMealTitle PLATE',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                      ),
                      onPressed: _isProcessing ? null : () => _verifyAndClaimMeal(activeMealTitle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
