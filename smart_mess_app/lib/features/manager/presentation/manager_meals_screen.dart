import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/weekly_menu.dart';

class ManagerMealsScreen extends StatefulWidget {
  const ManagerMealsScreen({super.key});

  @override
  State<ManagerMealsScreen> createState() => _ManagerMealsScreenState();
}

class _ManagerMealsScreenState extends State<ManagerMealsScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday, 6 = Sunday

  // Local state initialized with schedule, and synced with Firestore
  late List<MenuItemData> _menuList;

  @override
  void initState() {
    super.initState();
    _menuList = List.from(WeeklyMenuData.schedule);
    _loadCustomMenuFromFirestore();
  }

  void _loadCustomMenuFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('weekly_menu').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final days = data['days'] as List<dynamic>?;
        if (days != null && days.isNotEmpty) {
          setState(() {
            _menuList = days.map((d) {
              final b = d['breakfast'] ?? {};
              final l = d['lunch'] ?? {};
              final dn = d['dinner'] ?? {};
              return MenuItemData(
                dayHindi: d['dayHindi'] ?? '',
                dayEnglish: d['dayEnglish'] ?? '',
                breakfast: MealSlot(
                  nameHindi: 'नाश्ता',
                  nameEnglish: 'Breakfast',
                  servingTime: b['servingTime'] ?? '08:00 AM - 09:30 AM',
                  cutoffTime: b['cutoffTime'] ?? '07:00 AM',
                  cutoffHour: 7,
                  cutoffMinute: 0,
                  itemsHindi: b['itemsHindi'] ?? '',
                  itemsEnglish: b['itemsEnglish'] ?? '',
                  price: b['price'] ?? 25,
                ),
                lunch: MealSlot(
                  nameHindi: 'दोपहर का भोजन',
                  nameEnglish: 'Lunch',
                  servingTime: l['servingTime'] ?? '01:00 PM - 02:30 PM',
                  cutoffTime: l['cutoffTime'] ?? '11:00 AM',
                  cutoffHour: 11,
                  cutoffMinute: 0,
                  itemsHindi: l['itemsHindi'] ?? '',
                  itemsEnglish: l['itemsEnglish'] ?? '',
                  price: l['price'] ?? 50,
                ),
                dinner: MealSlot(
                  nameHindi: 'रात का भोजन',
                  nameEnglish: 'Dinner',
                  servingTime: dn['servingTime'] ?? '08:00 PM - 09:30 PM',
                  cutoffTime: dn['cutoffTime'] ?? '06:00 PM',
                  cutoffHour: 18,
                  cutoffMinute: 0,
                  itemsHindi: dn['itemsHindi'] ?? '',
                  itemsEnglish: dn['itemsEnglish'] ?? '',
                  price: dn['price'] ?? 50,
                ),
              );
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _showEditMealDialog(BuildContext context, int dayIndex, String mealType, MealSlot slot) {
    final hindiController = TextEditingController(text: slot.itemsHindi);
    final engController = TextEditingController(text: slot.itemsEnglish);
    final timeController = TextEditingController(text: slot.servingTime);
    final cutoffController = TextEditingController(text: slot.cutoffTime);
    final priceController = TextEditingController(text: slot.price.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF1B5E20), size: 22),
            const SizedBox(width: 8),
            Text('Edit $mealType Menu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_menuList[dayIndex].dayEnglish} (${_menuList[dayIndex].dayHindi})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: engController,
                decoration: InputDecoration(
                  labelText: 'Menu Items (English)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hindiController,
                decoration: InputDecoration(
                  labelText: 'Menu Items (Hindi)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Serving Time',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cutoffController,
                      decoration: InputDecoration(
                        labelText: 'Cutoff Time',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Meal Price (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newSlot = MealSlot(
                nameHindi: slot.nameHindi,
                nameEnglish: slot.nameEnglish,
                servingTime: timeController.text.trim(),
                cutoffTime: cutoffController.text.trim(),
                cutoffHour: slot.cutoffHour,
                cutoffMinute: slot.cutoffMinute,
                itemsHindi: hindiController.text.trim(),
                itemsEnglish: engController.text.trim(),
                price: int.tryParse(priceController.text.trim()) ?? slot.price,
                isAvailable: slot.isAvailable,
              );

              final currentDay = _menuList[dayIndex];
              final updatedDay = MenuItemData(
                dayHindi: currentDay.dayHindi,
                dayEnglish: currentDay.dayEnglish,
                breakfast: mealType == 'Breakfast' ? newSlot : currentDay.breakfast,
                lunch: mealType == 'Lunch' ? newSlot : currentDay.lunch,
                dinner: mealType == 'Dinner' ? newSlot : currentDay.dinner,
              );

              setState(() {
                _menuList[dayIndex] = updatedDay;
              });

              Navigator.pop(dialogCtx);

              // Sync to Cloud Firestore
              try {
                final daysJson = _menuList.map((d) => {
                  'dayEnglish': d.dayEnglish,
                  'dayHindi': d.dayHindi,
                  'breakfast': {
                    'itemsEnglish': d.breakfast.itemsEnglish,
                    'itemsHindi': d.breakfast.itemsHindi,
                    'servingTime': d.breakfast.servingTime,
                    'cutoffTime': d.breakfast.cutoffTime,
                    'price': d.breakfast.price,
                  },
                  'lunch': {
                    'itemsEnglish': d.lunch.itemsEnglish,
                    'itemsHindi': d.lunch.itemsHindi,
                    'servingTime': d.lunch.servingTime,
                    'cutoffTime': d.lunch.cutoffTime,
                    'price': d.lunch.price,
                  },
                  'dinner': {
                    'itemsEnglish': d.dinner.itemsEnglish,
                    'itemsHindi': d.dinner.itemsHindi,
                    'servingTime': d.dinner.servingTime,
                    'cutoffTime': d.dinner.cutoffTime,
                    'price': d.dinner.price,
                  },
                }).toList();

                final webFormatDays = _menuList.map((d) => {
                  'id': d.dayEnglish.toLowerCase().substring(0, 3),
                  'dayEnglish': d.dayEnglish,
                  'dayHindi': d.dayHindi,
                  'breakfast': {
                    'itemsEnglish': d.breakfast.itemsEnglish,
                    'itemsHindi': d.breakfast.itemsHindi,
                    'time': d.breakfast.servingTime,
                    'cutoff': d.breakfast.cutoffTime,
                    'price': d.breakfast.price,
                  },
                  'lunch': {
                    'itemsEnglish': d.lunch.itemsEnglish,
                    'itemsHindi': d.lunch.itemsHindi,
                    'time': d.lunch.servingTime,
                    'cutoff': d.lunch.cutoffTime,
                    'price': d.lunch.price,
                  },
                  'dinner': {
                    'itemsEnglish': d.dinner.itemsEnglish,
                    'itemsHindi': d.dinner.itemsHindi,
                    'time': d.dinner.servingTime,
                    'cutoff': d.dinner.cutoffTime,
                    'price': d.dinner.price,
                  },
                }).toList();

                await FirebaseFirestore.instance.collection('settings').doc('weekly_menu').set({
                  'days': daysJson,
                  'daysJson': jsonEncode(webFormatDays),
                  'updatedAt': DateTime.now().toIso8601String(),
                }, SetOptions(merge: true));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated $mealType menu for ${currentDay.dayEnglish} and synced to cloud!'),
                      backgroundColor: const Color(0xFF1B5E20),
                    ),
                  );
                }
              } catch (_) {}
            },
            child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _menuList.length) {
      _selectedDayIndex = 0;
    }
    final currentDayMenu = _menuList[_selectedDayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Weekly Meal Menu & Timings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
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
                children: List.generate(_menuList.length, (index) {
                  final item = _menuList[index];
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
                        fontSize: 12,
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

          // Meal Slots Details with Edit Option
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMealCard('Breakfast', 'नाश्ता', currentDayMenu.breakfast, Icons.wb_sunny_outlined, const Color(0xFFE65100), const Color(0xFFFFF3E0), _selectedDayIndex),
                const SizedBox(height: 14),
                _buildMealCard('Lunch', 'दोपहर का भोजन', currentDayMenu.lunch, Icons.restaurant, const Color(0xFF1B5E20), const Color(0xFFE8F5E9), _selectedDayIndex),
                const SizedBox(height: 14),
                _buildMealCard('Dinner', 'रात का भोजन', currentDayMenu.dinner, Icons.nightlight_round, const Color(0xFF1565C0), const Color(0xFFE3F2FD), _selectedDayIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String mealType, String hindiType, MealSlot slot, IconData icon, Color primaryColor, Color bgColor, int dayIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Text('$mealType / $hindiType', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: primaryColor), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('₹${slot.price}', style: TextStyle(fontWeight: FontWeight.w800, color: primaryColor, fontSize: 12.5)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: primaryColor),
                    tooltip: 'Edit $mealType Menu',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditMealDialog(context, dayIndex, mealType, slot),
                  ),
                ],
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('Serving: ${slot.servingTime}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_off_outlined, size: 14, color: Color(0xFFC62828)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('Cutoff: ${slot.cutoffTime}', style: const TextStyle(fontSize: 11, color: Color(0xFFC62828), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
