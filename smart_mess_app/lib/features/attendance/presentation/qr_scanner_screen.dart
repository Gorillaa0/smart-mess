import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/weekly_menu.dart';
import '../providers/attendance_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  bool _isProcessing = false;
  bool _cameraPermissionError = false;
  String? _errorMessage;
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: _cameraFacing,
      torchEnabled: _torchEnabled,
      autoStart: true,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String _resolveMealType(String? qrCode) {
    final clean = (qrCode ?? '').toLowerCase();
    if (clean.contains('breakfast') || clean.contains('नाश्ता')) return 'Breakfast';
    if (clean.contains('lunch') || clean.contains('दोपहर')) return 'Lunch';
    if (clean.contains('dinner') || clean.contains('रात') || clean.contains('रात्रि')) return 'Dinner';

    // Time-based fallback
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    const bkEnd = 10 * 60; // 10:00 AM
    const lunchEnd = 15 * 60 + 30; // 03:30 PM

    if (currentMinutes < bkEnd) {
      return 'Breakfast';
    } else if (currentMinutes < lunchEnd) {
      return 'Lunch';
    } else {
      return 'Dinner';
    }
  }

  // AUTOMATIC VERIFICATION TRIGGERED ONLY WHEN QR CODE IS DETECTED
  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        final mealType = _resolveMealType(code.trim());

        // Automatically verify and claim meal plate
        _verifyAndClaimMeal(mealType, qrToken: code.trim());
        break;
      }
    }
  }

  void _verifyAndClaimMeal(String mealType, {required String qrToken}) {
    if (_isProcessing) return;

    final student = ref.read(currentStudentProvider);
    final attendanceNotifier = ref.read(liveAttendanceProvider.notifier);

    if (attendanceNotifier.hasScanned(student.registrationNo, mealType)) {
      _showAlreadyScannedDialog(student.name, mealType);
      return;
    }

    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 400), () async {
      final success = await attendanceNotifier.recordScan(student, mealType);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          _showSuccessDialog(
            student.name,
            student.registrationNo,
            student.rollNo,
            student.branch,
            student.roomNo,
            mealType,
            qrToken: qrToken,
          );
        }
      }
    });
  }

  void _showSuccessDialog(
    String name,
    String regNo,
    String rollNo,
    String branch,
    String roomNo,
    String mealType, {
    required String qrToken,
  }) {
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 44),
            ),
            const SizedBox(height: 14),
            const Text(
              'MEAL PLATE VERIFIED!',
              style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Hostel Number 4 Kitchen Counter',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

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
            const SizedBox(height: 12),

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
            const SizedBox(height: 18),

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

  Future<void> _requestCameraPermission() async {
    setState(() {
      _cameraPermissionError = false;
      _errorMessage = null;
    });
    try {
      await _scannerController.start();
    } catch (e) {
      setState(() {
        _cameraPermissionError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final now = DateTime.now();
    final activeMeal = WeeklyMenuData.getActiveMealState(now);
    final activeMealTitle = activeMeal.meal?.nameEnglish ?? 'Lunch';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Meal Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: () {
              setState(() => _torchEnabled = !_torchEnabled);
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () {
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
              });
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. LIVE CAMERA SCANNER VIEW
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: const Color(0xFF111827),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_outlined, color: Colors.orangeAccent, size: 52),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please tap below to allow camera permission in your browser to scan the mess counter QR code.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('ALLOW CAMERA ACCESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: _requestCameraPermission,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. SCANNING RETICLE / VIEWFINDER OVERLAY (Wrapped in IgnorePointer so taps pass through)
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    // Corner brackets
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.shade400, width: 2.5),
                      ),
                    ),

                    // Animated Scanning Laser
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value * 240,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Color(0xFF00E676), Colors.transparent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. TOP STUDENT INFO BADGE
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Reg: ${student.registrationNo} • Room ${student.roomNo} (${student.branch})',
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. BOTTOM SCANNING STATUS PANEL (AUTOMATIC SCAN INSTRUCTIONS)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE MEAL SESSION',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            Text(
                              activeMealTitle.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isProcessing ? const Color(0xFFE65100) : const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            if (_isProcessing) ...[
                              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.8)),
                              const SizedBox(width: 6),
                              const Text('VERIFYING...', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ] else ...[
                              const Icon(Icons.qr_code_scanner, size: 13, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              const Text('AUTO-SCAN LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clear instruction container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.center_focus_strong, color: Colors.greenAccent, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Point camera at the Mess Counter QR Code. Your meal plate will be automatically verified upon scanning.',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
