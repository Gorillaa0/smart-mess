class MenuItemData {
  final String dayHindi;
  final String dayEnglish;
  final MealSlot breakfast;
  final MealSlot lunch;
  final MealSlot dinner;

  const MenuItemData({
    required this.dayHindi,
    required this.dayEnglish,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
}

class MealSlot {
  final String nameHindi;
  final String nameEnglish;
  final String servingTime;
  final String cutoffTime;
  final int cutoffHour;
  final int cutoffMinute;
  final String itemsHindi;
  final String itemsEnglish;
  final int price;
  final bool isAvailable;

  const MealSlot({
    required this.nameHindi,
    required this.nameEnglish,
    required this.servingTime,
    required this.cutoffTime,
    required this.cutoffHour,
    required this.cutoffMinute,
    required this.itemsHindi,
    required this.itemsEnglish,
    required this.price,
    this.isAvailable = true,
  });
}

class WeeklyMenuData {
  static const List<MenuItemData> schedule = [
    // 1. Monday
    MenuItemData(
      dayHindi: 'सोमवार',
      dayEnglish: 'Monday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'मुगलाई पराठा-1 / सूजी पराठा-3, सब्जी, हलवा',
        itemsEnglish: 'Mughlai / Sooji Paratha, Sabji, Halwa',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल, सब्जी, भुजिया, सलाद',
        itemsEnglish: 'Roti, Rice, Dal, Sabji, Bhujia, Salad',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, मटरपनीर',
        itemsEnglish: 'Roti, Matar Paneer',
        price: 50,
      ),
    ),

    // 2. Tuesday
    MenuItemData(
      dayHindi: 'मंगलवार',
      dayEnglish: 'Tuesday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'आलू पराठा-3, सब्जी',
        itemsEnglish: 'Aloo Paratha (3 pcs), Sabji',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल, सब्जी, चोखा, पापड़',
        itemsEnglish: 'Roti, Rice, Dal, Sabji, Chokha, Papad',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, जीरा राईस, दाल तड़का, भुजिया',
        itemsEnglish: 'Roti, Jeera Rice, Dal Tadka, Bhujia',
        price: 50,
      ),
    ),

    // 3. Wednesday (Special Dinner Non-Veg / Paneer: ₹100)
    MenuItemData(
      dayHindi: 'बुधवार',
      dayEnglish: 'Wednesday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'पूरी-6, सब्जी, जलेबी-2',
        itemsEnglish: 'Poori (6 pcs), Sabji, Jalebi (2 pcs)',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल, मौसमी सब्जी, पकोड़ा, सलाद',
        itemsEnglish: 'Roti, Rice, Dal, Seasonal Sabji, Pakoda, Salad',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Special Feast Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल तड़का, पनीर-4 / चिकन-2 पीस, सलाद',
        itemsEnglish: 'Roti, Rice, Dal Tadka, Paneer / Chicken (2 pcs), Salad',
        price: 100,
      ),
    ),

    // 4. Thursday
    MenuItemData(
      dayHindi: 'गुरुवार',
      dayEnglish: 'Thursday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'इटली-4 सांभर / पूरी-6, सब्जी',
        itemsEnglish: 'Idli (4 pcs) Sambar / Poori (6 pcs), Sabji',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल, सब्जी, चोखा, सलाद, पापड़',
        itemsEnglish: 'Roti, Rice, Dal, Sabji, Chokha, Salad, Papad',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'पूरी, सब्जी, सेवई',
        itemsEnglish: 'Poori, Sabji, Sewai',
        price: 50,
      ),
    ),

    // 5. Friday
    MenuItemData(
      dayHindi: 'शुक्रवार',
      dayEnglish: 'Friday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'पराठा-3, भुजिया',
        itemsEnglish: 'Plain Paratha (3 pcs), Bhujia',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चावल, दाल, मौसमी सब्जी, भुजिया',
        itemsEnglish: 'Roti, Rice, Dal, Seasonal Sabji, Bhujia',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'अंडा करी-2 पीस / पनीर-4 पीस, मिठाई, रोटी, दाल, चावल',
        itemsEnglish: 'Egg Curry / Paneer, Sweet, Roti, Dal, Rice',
        price: 50,
      ),
    ),

    // 6. Saturday
    MenuItemData(
      dayHindi: 'शनिवार',
      dayEnglish: 'Saturday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast',
        servingTime: '08:00 AM - 09:30 AM',
        cutoffTime: '07:00 AM',
        cutoffHour: 7,
        cutoffMinute: 0,
        itemsHindi: 'छोला भटूरा-2, अचार',
        itemsEnglish: 'Chole Bhature (2 pcs), Pickle',
        price: 25,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'राजमा, चावल, भुजिया, पापड़, सलाद',
        itemsEnglish: 'Rajma, Rice, Bhujia, Papad, Salad',
        price: 50,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'सत्तू पराठा, सब्जी, सलाद, लाल चटनी',
        itemsEnglish: 'Sattu Paratha, Sabji, Salad, Red Chutney',
        price: 50,
      ),
    ),

    // 7. Sunday (No Breakfast; Special Feast Lunch: ₹100; Regular Dinner: ₹50)
    MenuItemData(
      dayHindi: 'रविवार',
      dayEnglish: 'Sunday',
      breakfast: MealSlot(
        nameHindi: 'नाश्ता',
        nameEnglish: 'Breakfast (Mess Closed)',
        servingTime: 'Closed',
        cutoffTime: 'N/A',
        cutoffHour: 0,
        cutoffMinute: 0,
        itemsHindi: 'रविवार को नाश्ता उपलब्ध नहीं है (मेस बंद)',
        itemsEnglish: 'No Breakfast served on Sundays',
        price: 0,
        isAvailable: false,
      ),
      lunch: MealSlot(
        nameHindi: 'मध्याह्न भोजन',
        nameEnglish: 'Special Feast Lunch',
        servingTime: '01:00 PM - 02:30 PM',
        cutoffTime: '11:00 AM',
        cutoffHour: 11,
        cutoffMinute: 0,
        itemsHindi: 'पुलाव, चिकन - 2 पीस / मशरूम 4- पीस, मिठाई, सलाद',
        itemsEnglish: 'Pulao, Chicken (2 pcs) / Mushroom (4 pcs), Sweet, Salad',
        price: 100,
      ),
      dinner: MealSlot(
        nameHindi: 'रात्रि भोजन',
        nameEnglish: 'Dinner',
        servingTime: '08:00 PM - 09:30 PM',
        cutoffTime: '06:00 PM',
        cutoffHour: 18,
        cutoffMinute: 0,
        itemsHindi: 'रोटी, चना सब्जी, खीर',
        itemsEnglish: 'Roti, Chana Sabji, Kheer',
        price: 50,
      ),
    ),
  ];

  static MenuItemData getTodayMenu([DateTime? date]) {
    final now = date ?? DateTime.now();
    final index = (now.weekday - 1) % 7;
    return schedule[index];
  }

  static MenuItemData getTomorrowMenu([DateTime? date]) {
    final now = (date ?? DateTime.now()).add(const Duration(days: 1));
    final index = (now.weekday - 1) % 7;
    return schedule[index];
  }

  /// Calculates the active/upcoming meal based on current time:
  /// - Before 10:30 AM -> Breakfast (if Sunday and no breakfast, skips to Sunday Lunch)
  /// - 10:30 AM to 03:30 PM -> Lunch
  /// - 03:30 PM to 10:00 PM -> Dinner
  /// - After 10:00 PM -> Closed for today (Shows Tomorrow's Breakfast)
  static ActiveMealStatus getActiveMealState([DateTime? customTime]) {
    final now = customTime ?? DateTime.now();
    final today = getTodayMenu(now);
    final tomorrow = getTomorrowMenu(now);

    final currentMinutes = now.hour * 60 + now.minute;
    const breakfastEnd = 10 * 60 + 30; // 10:30 AM = 630 mins
    const lunchEnd = 15 * 60 + 30;    // 03:30 PM = 930 mins
    const dinnerEnd = 22 * 60 + 0;    // 10:00 PM = 1320 mins

    if (currentMinutes < breakfastEnd) {
      if (!today.breakfast.isAvailable) {
        // Sunday morning: No breakfast -> show upcoming Sunday Lunch
        return ActiveMealStatus(
          meal: today.lunch,
          statusText: 'SUNDAY SPECIAL LUNCH (UPCOMING)',
          isClosedForToday: false,
          dayName: today.dayHindi,
        );
      }
      return ActiveMealStatus(
        meal: today.breakfast,
        statusText: 'BREAKFAST (TODAY)',
        isClosedForToday: false,
        dayName: today.dayHindi,
      );
    } else if (currentMinutes < lunchEnd) {
      return ActiveMealStatus(
        meal: today.lunch,
        statusText: 'LUNCH (TODAY)',
        isClosedForToday: false,
        dayName: today.dayHindi,
      );
    } else if (currentMinutes < dinnerEnd) {
      return ActiveMealStatus(
        meal: today.dinner,
        statusText: 'DINNER (TODAY)',
        isClosedForToday: false,
        dayName: today.dayHindi,
      );
    } else {
      // Dinner has passed!
      return ActiveMealStatus(
        meal: null,
        statusText: 'ALL MEALS COMPLETED FOR TODAY',
        isClosedForToday: true,
        nextMealTomorrow: tomorrow.breakfast.isAvailable ? tomorrow.breakfast : tomorrow.lunch,
        dayName: today.dayHindi,
      );
    }
  }
}

class ActiveMealStatus {
  final MealSlot? meal;
  final String statusText;
  final bool isClosedForToday;
  final MealSlot? nextMealTomorrow;
  final String dayName;

  const ActiveMealStatus({
    required this.meal,
    required this.statusText,
    required this.isClosedForToday,
    this.nextMealTomorrow,
    required this.dayName,
  });
}
