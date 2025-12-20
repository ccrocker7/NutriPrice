import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';
import '../models/weight_entry.dart';

class DatabaseService {
  // Three separate boxes
  static const String productsBoxName = "products_box";
  static const String diaryBoxName = "diary_box";
  static const String pantryBoxName = "pantry_box";
  static const String weightBoxName = "weight_box";

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(productsBoxName);
    await Hive.openBox(diaryBoxName);
    await Hive.openBox(pantryBoxName);
    await Hive.openBox(weightBoxName);
  }

  // ===== PRODUCTS (Master List) =====

  // Save product to master list
  static Future<void> saveProduct(FoodProduct product) async {
    final box = Hive.box(productsBoxName);
    await box.add(product.toMap());
  }

  // Get all products from master list
  List<FoodProduct> getAllProducts() {
    final box = Hive.box(productsBoxName);
    return box.values.map((item) => FoodProduct.fromMap(item)).toList();
  }

  // ===== DIARY =====

  // Add product to diary
  static Future<void> addToDiary(FoodProduct product) async {
    final box = Hive.box(diaryBoxName);
    // Ensure dateAdded is set
    final entry = product.dateAdded != null
        ? product
        : FoodProduct(
            name: product.name,
            brand: product.brand,
            calories: product.calories,
            fat: product.fat,
            carbs: product.carbs,
            fiber: product.fiber,
            sodium: product.sodium,
            protein: product.protein,
            price: product.price,
            quantity: product.quantity,
            unit: product.unit,
            dateAdded: DateTime.now(),
          );
    await box.add(entry.toMap());
  }

  // Get diary entries
  List<FoodProduct> getDiaryEntries() {
    final box = Hive.box(diaryBoxName);
    return box.values.map((item) => FoodProduct.fromMap(item)).toList();
  }

  // Delete from diary by index
  Future<void> deleteDiaryEntry(int index) async {
    final box = Hive.box(diaryBoxName);
    await box.deleteAt(index);
  }

  // ===== PANTRY =====

  // Add product to pantry
  static Future<void> addToPantry(FoodProduct product) async {
    final box = Hive.box(pantryBoxName);
    await box.add(product.toMap());
  }

  // Get pantry items
  List<FoodProduct> getPantryItems() {
    final box = Hive.box(pantryBoxName);
    return box.values.map((item) => FoodProduct.fromMap(item)).toList();
  }

  // Delete from pantry by index
  Future<void> deletePantryItem(int index) async {
    final box = Hive.box(pantryBoxName);
    await box.deleteAt(index);
  }

  // ===== MOVE LOGIC =====

  // Move quantity from Pantry to Diary
  // Returns true if successful, false if not found or insufficient quantity (optional)
  static Future<void> moveFromPantryToDiary(
    FoodProduct product,
    double amountToMove,
  ) async {
    final pantryBox = Hive.box(pantryBoxName);
    final diaryBox = Hive.box(diaryBoxName);

    // 1. Find the item in Pantry (match name and brand)
    int pantryIndex = -1;
    FoodProduct? pantryItem;

    // Iterate through keys so we have the index/key for updates
    for (int i = 0; i < pantryBox.length; i++) {
      final raw = pantryBox.getAt(i) as Map<dynamic, dynamic>;
      final p = FoodProduct.fromMap(raw);
      if (p.name == product.name && p.brand == product.brand) {
        pantryIndex = i;
        pantryItem = p;
        break;
      }
    }

    // 3. Update Pantry (and determine cost)
    String? diaryPrice = product.price; // Default if not in pantry

    if (pantryIndex != -1 && pantryItem != null) {
      // Parse current pantry quantity and price
      double currentQty = double.tryParse(pantryItem.quantity ?? '0') ?? 1;
      double currentPrice = double.tryParse(pantryItem.price ?? '0') ?? 0;

      // Prevent division by zero
      if (currentQty <= 0) currentQty = 1;

      // Calculate unit price and cost for the moved amount
      double unitPrice = currentPrice / currentQty;
      double movedCost = unitPrice * amountToMove;
      diaryPrice = movedCost.toStringAsFixed(2);

      double newQty = currentQty - amountToMove;
      double newRemainingPrice = unitPrice * newQty;
      // Ensure we don't end up with negative price due to float precision
      if (newRemainingPrice < 0) newRemainingPrice = 0;

      if (newQty <= 0) {
        // Remove from pantry if used up
        await pantryBox.deleteAt(pantryIndex);
      } else {
        // Update quantity and price in Pantry
        final updatedPantryItem = FoodProduct(
          name: pantryItem.name,
          brand: pantryItem.brand,
          calories: pantryItem.calories,
          fat: pantryItem.fat,
          carbs: pantryItem.carbs,
          fiber: pantryItem.fiber,
          sodium: pantryItem.sodium,
          protein: pantryItem.protein,
          price: newRemainingPrice.toStringAsFixed(2),
          quantity: newQty.toString(), // Store as simple string
          unit: pantryItem.unit,
        );
        await pantryBox.putAt(pantryIndex, updatedPantryItem.toMap());
      }
    }

    // 2. Add to Diary (moved step 2 after step 3 logic to use calculated price)
    // Create diary entry with the specific amount moved and calculated price
    final diaryEntry = FoodProduct(
      name: product.name,
      brand: product.brand,
      calories: product.calories,
      fat: product.fat,
      carbs: product.carbs,
      fiber: product.fiber,
      sodium: product.sodium,
      protein: product.protein,
      price: diaryPrice,
      quantity: amountToMove.toString(),
      unit: product.unit,
      dateAdded: DateTime.now(),
    );
    await diaryBox.add(diaryEntry.toMap());
  }

  // ===== UPDATE LOGIC =====

  // Update diary entry at index
  static Future<void> updateDiaryEntry(int index, FoodProduct product) async {
    final box = Hive.box(diaryBoxName);
    await box.putAt(index, product.toMap());
  }

  // Get ValueListenable for diary
  static ValueListenable<Box> getDiaryListenable() {
    return Hive.box(diaryBoxName).listenable();
  }

  // Update pantry item at index
  static Future<void> updatePantryItem(int index, FoodProduct product) async {
    final box = Hive.box(pantryBoxName);
    await box.putAt(index, product.toMap());
  }

  // Update master product (find by name+brand)
  static Future<void> updateMasterProduct(FoodProduct product) async {
    final box = Hive.box(productsBoxName);

    int indexToUpdate = -1;
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i) as Map<dynamic, dynamic>;
      final p = FoodProduct.fromMap(raw);
      if (p.name == product.name && p.brand == product.brand) {
        indexToUpdate = i;
        break;
      }
    }

    if (indexToUpdate != -1) {
      await box.putAt(indexToUpdate, product.toMap());
    }
  }

  // Delete product from master list (find by name+brand)
  static Future<void> deleteProduct(FoodProduct product) async {
    final box = Hive.box(productsBoxName);

    int indexToDelete = -1;
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i) as Map<dynamic, dynamic>;
      final p = FoodProduct.fromMap(raw);
      if (p.name == product.name && p.brand == product.brand) {
        indexToDelete = i;
        break;
      }
    }

    if (indexToDelete != -1) {
      await box.deleteAt(indexToDelete);
    }
  }

  // ===== WEIGHT TRACKING =====

  // Save weight entry
  static Future<void> saveWeight(WeightEntry entry) async {
    final box = Hive.box(weightBoxName);
    await box.add(entry.toMap());
  }

  // Get weight history
  static List<WeightEntry> getWeightHistory() {
    final box = Hive.box(weightBoxName);
    final entries = box.values
        .map((item) => WeightEntry.fromMap(item))
        .toList();
    // Sort by date, newest first
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // Get ValueListenable for weight history
  static ValueListenable<Box> getWeightHistoryListenable() {
    return Hive.box(weightBoxName).listenable();
  }

  // Calculate Estimated TDEE for 'now'
  static double? calculateEstimatedTDEE() {
    return calculateTDEEForDate(DateTime.now());
  }

  // Calculate TDEE for a specific date lookback (30 days prior to given date)
  static double? calculateTDEEForDate(DateTime endDate) {
    final weightBox = Hive.box(weightBoxName);
    final diaryBox = Hive.box(diaryBoxName);

    // 1. Get data for last 30 days relative to endDate
    final startDate = endDate.subtract(const Duration(days: 30));

    // Weight Entries: Filter for [startDate, endDate]
    final weightEntries = weightBox.values
        .map((item) => WeightEntry.fromMap(item))
        .where(
          (e) =>
              e.date.isAfter(startDate) &&
              e.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
    // Sort by date ascending
    weightEntries.sort((a, b) => a.date.compareTo(b.date));

    // Diary Entries: Filter for [startDate, endDate]
    final diaryEntries = diaryBox.values
        .map((item) => FoodProduct.fromMap(item))
        .where(
          (e) =>
              e.dateAdded != null &&
              e.dateAdded!.isAfter(startDate) &&
              e.dateAdded!.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();

    // 2. Validation
    if (weightEntries.length < 2) return null;

    final firstWeight = weightEntries.first;
    final lastWeight = weightEntries.last;

    final daysElapsed = lastWeight.date.difference(firstWeight.date).inDays;
    if (daysElapsed < 1) return null;

    // 3. Weight Change
    final weightChange = lastWeight.weight - firstWeight.weight;

    // 4. Maintenance Adjustment
    // 3500 kcal per lb.
    final dailySurplusDeficit = (weightChange * 3500) / daysElapsed;

    // 5. Avg Intake
    // Filter relevant diary strictly within the weight window
    final relevantDiary = diaryEntries
        .where(
          (e) =>
              e.dateAdded!.isAfter(
                firstWeight.date.subtract(const Duration(hours: 12)),
              ) &&
              e.dateAdded!.isBefore(
                lastWeight.date.add(const Duration(hours: 12)),
              ),
        )
        .toList();

    double totalCalories = 0;
    for (var entry in relevantDiary) {
      double cals = double.tryParse(entry.calories ?? '0') ?? 0;
      totalCalories += cals;
    }

    final dailyIntake = totalCalories / daysElapsed;

    // 6. TDEE
    final tdee = dailyIntake - dailySurplusDeficit;

    return tdee > 0 ? tdee : null;
  }

  // Get TDEE History for chart
  static List<Map<String, dynamic>> getTDEEHistory({int days = 30}) {
    final history = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i - 1));
      final tdee = calculateTDEEForDate(date);
      if (tdee != null) {
        history.add({'date': date, 'tdee': tdee});
      }
    }
    return history;
  }
}
