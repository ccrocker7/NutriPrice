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
  final String? unitPrice;
  final double? servingQuantity;
  final String? servingUnit;
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
    this.unitPrice,
    this.servingQuantity,
    this.servingUnit,
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
      'unitPrice': unitPrice,
      'servingQuantity': servingQuantity,
      'servingUnit': servingUnit,
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
      unitPrice: map['unitPrice'],
      servingQuantity: map['servingQuantity'] != null
          ? (map['servingQuantity'] as num).toDouble()
          : null,
      servingUnit: map['servingUnit'],
      dateAdded: map['dateAdded'] != null
          ? DateTime.tryParse(map['dateAdded'])
          : null,
    );
  }

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final nutrients = product['nutriments'] ?? {};

    // Helper to get serving-based nutrient or calculate it from 100g
    String? getNutrient(String key) {
      final servingValue = nutrients['${key}_serving'];
      if (servingValue != null) return servingValue.toString();

      final value100g = nutrients['${key}_100g'];
      if (value100g == null) return null;

      final servingQty = product['serving_quantity'] != null
          ? (product['serving_quantity'] as num).toDouble()
          : null;

      if (servingQty != null) {
        double density = (value100g as num).toDouble() / 100.0;
        return (density * servingQty).toStringAsFixed(2);
      }
      return value100g.toString();
    }

    return FoodProduct(
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      calories: getNutrient('energy-kcal'),
      fat: getNutrient('fat'),
      carbs: getNutrient('carbohydrates'),
      fiber: getNutrient('fiber'),
      sodium: getNutrient('sodium'),
      protein: getNutrient('proteins'),
      price: null,
      quantity: '1',
      unit: 'Serving',
      servingQuantity: product['serving_quantity'] != null
          ? (product['serving_quantity'] as num).toDouble()
          : 1.0,
      servingUnit: product['serving_quantity_unit'],
      dateAdded: DateTime.now(),
    );
  }

  /// Calculates the multiplier to apply to base nutrients (which are per-serving).
  /// If unit is "Serving", multiplier = quantity.
  /// If unit is weight-based (e.g., "g"), multiplier = (quantity / servingQuantity).
  double getNutrientMultiplier() {
    double qty = double.tryParse(quantity ?? "1") ?? 1.0;
    if (unit == 'Serving' || unit == null) {
      return qty;
    }
    if (servingQuantity != null && servingQuantity! > 0) {
      return qty / servingQuantity!;
    }
    return qty;
  }
}
