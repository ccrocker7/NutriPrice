import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';

class DatabaseService {
  static const String boxName = "food_diary_box";

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  // Save product
  Future<void> saveProduct(FoodProduct product) async {
    final box = Hive.box(boxName);
    await box.add(product.toMap());
  }

  // Get all products
  List<FoodProduct> getAllProducts() {
    final box = Hive.box(boxName);
    return box.values.map((item) => FoodProduct.fromMap(item)).toList();
  }

  // Delete product by index
  Future<void> deleteProduct(int index) async {
    final box = Hive.box(boxName);
    await box.deleteAt(index);
  }
}