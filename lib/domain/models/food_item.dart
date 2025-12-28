import 'food_unit.dart';

class FoodItem {
  final String id, name;
  final double calories, fat, sodium, carbs, fiber, protein, price, servingSize;
  final FoodUnit servingUnit;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.fat,
    required this.sodium,
    required this.carbs,
    required this.fiber,
    required this.protein,
    required this.price,
    required this.servingSize,
    required this.servingUnit,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'fat': fat,
    'sodium': sodium,
    'carbs': carbs,
    'fiber': fiber,
    'protein': protein,
    'price': price,
    'servingSize': servingSize,
    'servingUnit': servingUnit.index,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Unknown',
    calories: (json['calories'] ?? 0.0).toDouble(),
    fat: (json['fat'] ?? 0.0).toDouble(),
    sodium: (json['sodium'] ?? 0.0).toDouble(),
    carbs: (json['carbs'] ?? 0.0).toDouble(),
    fiber: (json['fiber'] ?? 0.0).toDouble(),
    protein: (json['protein'] ?? 0.0).toDouble(),
    price: (json['price'] ?? 0.0).toDouble(),
    servingSize: (json['servingSize'] ?? 0.0).toDouble(),
    servingUnit: FoodUnit.values[json['servingUnit'] ?? 0],
  );
}
