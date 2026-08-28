import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ManagerQRScreen extends StatelessWidget {
  const ManagerQRScreen({super.key});

  static const String staticPayload =
      '{"system":"SmartMess","hostel":"Hostel Number 4","messId":"mess_h4","counter":"Main Dining Counter","type":"static_counter_qr"}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Permanent Mess QR Poster', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'HOSTEL 4 • PERMANENT DINING QR',
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Box
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: staticPayload,
                      version: QrVersions.auto,
                      size: 240.0,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'HOSTEL NUMBER 4 • DINING COUNTER',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1B5E20), letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Static Printable QR (Never Expires)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Offline / Testing Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.print_outlined, color: Colors.greenAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Testing Ready (No Screen Needed)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'You can print this QR code on physical paper or display it from another phone. Students can scan it anytime with the mobile app camera to verify their meal attendance.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
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
