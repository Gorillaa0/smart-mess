import 'package:flutter/material.dart';

class MealCardWidget extends StatelessWidget {
  final String title;
  final String items;
  final String timeWindow;
  final String type;
  final VoidCallback? onMessOffPressed;
  final bool isMessOffMarked;

  const MealCardWidget({
    super.key,
    required this.title,
    required this.items,
    required this.timeWindow,
    required this.type,
    this.onMessOffPressed,
    this.isMessOffMarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF2E7D32), width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(type, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(items, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(timeWindow, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                if (onMessOffPressed != null)
                  OutlinedButton(
                    onPressed: onMessOffPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isMessOffMarked ? Colors.grey : Colors.red,
                      side: BorderSide(color: isMessOffMarked ? Colors.grey : Colors.red),
                    ),
                    child: Text(isMessOffMarked ? 'Mess Off Marked' : 'Mark Mess Off'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
