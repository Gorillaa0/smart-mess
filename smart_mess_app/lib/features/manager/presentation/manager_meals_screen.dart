import 'package:flutter/material.dart';
import '../../../core/constants/weekly_menu.dart';

class ManagerMealsScreen extends StatefulWidget {
  const ManagerMealsScreen({super.key});

  @override
  State<ManagerMealsScreen> createState() => _ManagerMealsScreenState();
}

class _ManagerMealsScreenState extends State<ManagerMealsScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday, 6 = Sunday

  @override
  Widget build(BuildContext context) {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= WeeklyMenuData.schedule.length) {
      _selectedDayIndex = 0;
    }
    final currentDayMenu = WeeklyMenuData.schedule[_selectedDayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Mess Menu & Timings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: Column(
        children: [
          // Day Selector Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(WeeklyMenuData.schedule.length, (index) {
                  final item = WeeklyMenuData.schedule[index];
                  final isSelected = index == _selectedDayIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${item.dayEnglish} (${item.dayHindi})'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.5,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDayIndex = index);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          // Meal Slots Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMealCard('Breakfast / नाश्ता', currentDayMenu.breakfast, Icons.wb_sunny_outlined, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                const SizedBox(height: 14),
                _buildMealCard('Lunch / दोपहर का भोजन', currentDayMenu.lunch, Icons.restaurant, const Color(0xFF1B5E20), const Color(0xFFE8F5E9)),
                const SizedBox(height: 14),
                _buildMealCard('Dinner / रात का भोजन', currentDayMenu.dinner, Icons.nightlight_round, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, MealSlot slot, IconData icon, Color primaryColor, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: primaryColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹${slot.price}', style: TextStyle(fontWeight: FontWeight.w800, color: primaryColor, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(slot.itemsEnglish, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
          const SizedBox(height: 3),
          Text(slot.itemsHindi, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Serving: ${slot.servingTime}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.timer_off_outlined, size: 14, color: Color(0xFFC62828)),
                  const SizedBox(width: 4),
                  Text('Cutoff: ${slot.cutoffTime}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
