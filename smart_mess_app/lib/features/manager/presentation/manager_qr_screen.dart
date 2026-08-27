import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ManagerQRScreen extends StatefulWidget {
  const ManagerQRScreen({super.key});

  @override
  State<ManagerQRScreen> createState() => _ManagerQRScreenState();
}

class _ManagerQRScreenState extends State<ManagerQRScreen> {
  int secondsRemaining = 58;
  Timer? timer;
  String currentToken = 'SM_LUNCH_X7AB39';
  int scannedCount = 138;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (secondsRemaining > 1) {
            secondsRemaining--;
          } else {
            secondsRemaining = 60;
            currentToken = 'SM_LUNCH_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Live Meal QR Session', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Meal Info Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LUNCH • MAIN MESS (TODAY)',
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 24),

              // QR Code Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: currentToken,
                      version: QrVersions.auto,
                      size: 240.0,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentToken,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Countdown Ring & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: secondsRemaining / 60,
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Rotates in ${secondsRemaining}s (Anti-Abuse Protection)',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Live Counter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Live Checked-in: $scannedCount / 168',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
