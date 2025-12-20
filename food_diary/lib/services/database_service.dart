import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';

class DatabaseService {
  // Three separate boxes
  static const String productsBoxName = "products_box";
  static const String diaryBoxName = "diary_box";
  static const String pantryBoxName = "pantry_box";

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(productsBoxName);
    await Hive.openBox(diaryBoxName);
    await Hive.openBox(pantryBoxName);
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
    await box.add(product.toMap());
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
}
