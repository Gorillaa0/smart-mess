import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/attendance_provider.dart';

class MealHistoryScreen extends ConsumerWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: historyState.when(
        data: (records) {
          if (records.isEmpty) return const Center(child: Text('No meal history available'));
          return ListView.builder(
            itemCount: records.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = records[index];
              Color statusColor;
              switch (record.status) {
                case 'present': statusColor = Colors.green; break;
                case 'missed': statusColor = Colors.red; break;
                case 'mess-off': statusColor = Colors.orange; break;
                default: statusColor = Colors.grey;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: Color(0xFF2E7D32)),
                  title: Text(record.mealId), // Usually joined with Meal title
                  subtitle: Text(record.scannedAt.toString().split('.')[0]),
                  trailing: Chip(
                    label: Text(record.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: statusColor,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
