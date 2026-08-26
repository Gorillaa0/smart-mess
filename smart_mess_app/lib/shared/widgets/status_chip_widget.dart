import 'package:flutter/material.dart';

class StatusChipWidget extends StatelessWidget {
  final String status;

  const StatusChipWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'approved':
      case 'paid':
      case 'present':
      case 'resolved':
        bgColor = Colors.green;
        break;
      case 'pending':
      case 'in_progress':
      case 'mess-off':
        bgColor = Colors.orange;
        break;
      case 'rejected':
      case 'unpaid':
      case 'missed':
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
