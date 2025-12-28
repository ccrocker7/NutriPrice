import '../models/food_unit.dart';

/// Utility for converting between different food units
class UnitConverter {
  /// Standard grams per ounce conversion
  static const double kGramsPerOunce = 28.3495;

  /// Converts amount from one unit to another
  ///
  /// [amount] - The quantity to convert
  /// [from] - Source unit
  /// [to] - Target unit
  /// [servingSize] - Required for servings-based conversions
  static double convert({
    required double amount,
    required FoodUnit from,
    required FoodUnit to,
    required double servingSize,
  }) {
    // If same unit, no conversion needed
    if (from == to) return amount;

    // Convert to grams as intermediate unit
    double grams;
    switch (from) {
      case FoodUnit.grams:
        grams = amount;
        break;
      case FoodUnit.ounces:
        grams = amount * kGramsPerOunce;
        break;
      case FoodUnit.servings:
        grams = amount * servingSize;
        break;
    }

    // Convert from grams to target unit
    switch (to) {
      case FoodUnit.grams:
        return grams;
      case FoodUnit.ounces:
        return grams / kGramsPerOunce;
      case FoodUnit.servings:
        return servingSize > 0 ? grams / servingSize : 0;
    }
  }

  /// Checks if conversion is possible between units
  /// Servings-based conversions require serving size
  static bool canConvert({
    required FoodUnit from,
    required FoodUnit to,
    required double servingSize,
  }) {
    // Grams and ounces can always convert to each other
    if (from != FoodUnit.servings && to != FoodUnit.servings) {
      return true;
    }

    // Servings require a valid serving size
    return servingSize > 0;
  }

  /// Formats a quantity with its unit for display
  static String formatQuantity(double amount, FoodUnit unit) {
    if (amount == 0) return '0 ${unit.name}';

    // Show 1 decimal place for small amounts, 0 for large
    final formatted = amount < 10
        ? amount.toStringAsFixed(1)
        : amount.toStringAsFixed(0);

    return '$formatted ${unit.name}';
  }
}
