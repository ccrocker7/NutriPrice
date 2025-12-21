class FoodProduct {
  final String name;
  final String brand;
  final String? calories;
  final String? fat;
  final String? carbs;
  final String? fiber;
  final String? sodium;
  final String? protein;
  final String? price;
  final String? quantity;
  final String? unit;
  final DateTime? dateAdded;

  FoodProduct({
    required this.name,
    required this.brand,
    this.calories,
    this.fat,
    this.carbs,
    this.fiber,
    this.sodium,
    this.protein,
    this.price,
    this.quantity,
    this.unit,
    this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'calories': calories,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'sodium': sodium,
      'protein': protein,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  factory FoodProduct.fromMap(Map<dynamic, dynamic> map) {
    return FoodProduct(
      name: map['name'] ?? 'Unknown',
      brand: map['brand'] ?? 'Unknown',
      calories: map['calories'],
      fat: map['fat'],
      carbs: map['carbs'],
      fiber: map['fiber'],
      sodium: map['sodium'],
      protein: map['protein'],
      price: map['price'],
      quantity: map['quantity'],
      unit: map['unit'],
      dateAdded: map['dateAdded'] != null
          ? DateTime.tryParse(map['dateAdded'])
          : null,
    );
  }

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final nutrients = product['nutriments'] ?? {};

    return FoodProduct(
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      calories: nutrients['energy-kcal_100g']?.toString(),
      fat: nutrients['fat_100g']?.toString(),
      carbs: nutrients['carbohydrates_100g']?.toString(),
      fiber: nutrients['fiber_100g']?.toString(),
      sodium: nutrients['sodium_100g']?.toString(),
      protein: nutrients['proteins_100g']?.toString(),
      price: null,
      quantity: '1', // Default quantity
      unit: 'Serving', // Default unit
      dateAdded: DateTime.now(),
    );
  }
}
