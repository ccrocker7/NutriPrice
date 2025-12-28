import 'food_unit.dart';

class FoodItem {
  final String id, name;
  final double calories, fat, sodium, carbs, fiber, protein, price, servingSize;
  final FoodUnit servingUnit;

  // Inventory tracking fields
  final double quantityRemaining;
  final FoodUnit inventoryUnit;

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
    this.quantityRemaining = 0.0,
    FoodUnit? inventoryUnit,
  }) : inventoryUnit = inventoryUnit ?? servingUnit;

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
    'quantityRemaining': quantityRemaining,
    'inventoryUnit': inventoryUnit.index,
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
    quantityRemaining: (json['quantityRemaining'] ?? 0.0).toDouble(),
    inventoryUnit: json['inventoryUnit'] != null
        ? FoodUnit.values[json['inventoryUnit']]
        : null,
  );

  /// Creates a copy with updated fields
  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? fat,
    double? sodium,
    double? carbs,
    double? fiber,
    double? protein,
    double? price,
    double? servingSize,
    FoodUnit? servingUnit,
    double? quantityRemaining,
    FoodUnit? inventoryUnit,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      fat: fat ?? this.fat,
      sodium: sodium ?? this.sodium,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      protein: protein ?? this.protein,
      price: price ?? this.price,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      inventoryUnit: inventoryUnit ?? this.inventoryUnit,
    );
  }
}
