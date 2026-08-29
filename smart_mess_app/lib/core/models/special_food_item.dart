import 'package:flutter/material.dart';

class SpecialFoodItem {
  final String id;
  final String name;
  final String hindiName;
  final int price;
  final String description;
  final bool isAvailable;

  const SpecialFoodItem({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.price,
    required this.description,
    this.isAvailable = true,
  });

  SpecialFoodItem copyWith({
    String? id,
    String? name,
    String? hindiName,
    int? price,
    String? description,
    bool? isAvailable,
  }) {
    return SpecialFoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      hindiName: hindiName ?? this.hindiName,
      price: price ?? this.price,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'name': {'stringValue': name},
      'hindiName': {'stringValue': hindiName},
      'price': {'integerValue': price.toString()},
      'description': {'stringValue': description},
      'isAvailable': {'booleanValue': isAvailable},
    };
  }

  factory SpecialFoodItem.fromFirestoreJson(Map<String, dynamic> fields) {
    return SpecialFoodItem(
      id: fields['id']?['stringValue'] ?? '',
      name: fields['name']?['stringValue'] ?? 'Special Item',
      hindiName: fields['hindiName']?['stringValue'] ?? '',
      price: int.tryParse(fields['price']?['integerValue'] ?? '0') ?? 0,
      description: fields['description']?['stringValue'] ?? '',
      isAvailable: fields['isAvailable']?['booleanValue'] ?? true,
    );
  }
}

const List<SpecialFoodItem> kDefaultSpecialFoodMenu = [
  SpecialFoodItem(
    id: 'egg_roll',
    name: 'Special Double Egg Roll',
    hindiName: 'स्पेशल डबल एग रोल',
    price: 45,
    description: 'Crispy laccha paratha with 2 eggs, onions, green chili & sauces',
    isAvailable: true,
  ),
  SpecialFoodItem(
    id: 'paneer_roll',
    name: 'Paneer Tikka Roll',
    hindiName: 'पनीर टिक्का रोल',
    price: 60,
    description: 'Fresh grilled paneer cubes wrapped in toasted flaky paratha',
    isAvailable: true,
  ),
  SpecialFoodItem(
    id: 'chowmein',
    name: 'Veg Hakka Chowmein',
    hindiName: 'वेज हक्का चाउमीन',
    price: 40,
    description: 'Wok-tossed noodles with crunchy capsicum, cabbage & spicy seasoning',
    isAvailable: true,
  ),
  SpecialFoodItem(
    id: 'burger',
    name: 'Crispy Veg / Chicken Burger',
    hindiName: 'क्रिस्पी वेज / चिकन बर्गर',
    price: 50,
    description: 'Grilled patty with cheese slice, fresh lettuce, tomato & mayo',
    isAvailable: true,
  ),
  SpecialFoodItem(
    id: 'maggi',
    name: 'Special Cheese Butter Maggi',
    hindiName: 'चीज बटर मैगी',
    price: 35,
    description: 'Double noodles with melted Amul butter, cheese & veggies',
    isAvailable: true,
  ),
];
