import 'package:flutter/material.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String id;
  
  const ComplaintDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Food Quality Issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text('In Progress', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Date: 24th August 2024', style: TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('The rice served during lunch today was undercooked. Please look into the cooking process.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manager Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  SizedBox(height: 8),
                  Text('We apologize for the inconvenience. The kitchen staff has been informed to ensure proper boiling times.', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
