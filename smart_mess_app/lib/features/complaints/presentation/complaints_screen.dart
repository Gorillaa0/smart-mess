import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Overwrite the previously generated complaints screen to include floating button routing
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, 
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: const Text('Food Quality Issue'),
              subtitle: const Text('The rice was undercooked today.'),
              trailing: Chip(
                label: const Text('In Progress', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.orange,
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/complaints/submit'),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
