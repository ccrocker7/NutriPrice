import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/food_item.dart';

class PantryRepository {
  static const String _pantryKey = 'pantry';

  /// Loads all pantry items from SharedPreferences
  Future<List<FoodItem>> loadPantry() async {
    final prefs = await SharedPreferences.getInstance();
    final pantryStr = prefs.getString(_pantryKey);

    if (pantryStr == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(pantryStr);
      return jsonList.map((json) => FoodItem.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  /// Saves all pantry items to SharedPreferences
  Future<void> savePantry(List<FoodItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(_pantryKey, jsonEncode(jsonList));
  }

  /// Adds a single item to the pantry
  Future<void> addItem(FoodItem item) async {
    final items = await loadPantry();
    items.add(item);
    await savePantry(items);
  }

  /// Updates an existing item in the pantry
  Future<void> updateItem(FoodItem updatedItem) async {
    final items = await loadPantry();
    final index = items.indexWhere((item) => item.id == updatedItem.id);

    if (index != -1) {
      items[index] = updatedItem;
      await savePantry(items);
    }
  }

  /// Deletes an item from the pantry by ID
  Future<void> deleteItem(String id) async {
    final items = await loadPantry();
    items.removeWhere((item) => item.id == id);
    await savePantry(items);
  }
}
