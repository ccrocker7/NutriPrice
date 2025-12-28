import 'package:flutter/material.dart';
import '../../domain/models/food_item.dart';

/// Shows a bottom sheet to pick a food item from the pantry
Future<FoodItem?> showPantryPicker(
  BuildContext context,
  List<FoodItem> pantry,
) async {
  return showModalBottomSheet<FoodItem>(
    context: context,
    builder: (c) => ListView.builder(
      itemCount: pantry.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(pantry[i].name),
        onTap: () => Navigator.pop(c, pantry[i]),
      ),
    ),
  );
}
