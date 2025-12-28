import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_unit.dart';
import '../../providers/app_state.dart';

/// Shows a dialog to add or edit a food item amount for logging
void showAmountDialog(
  BuildContext context,
  FoodItem baseItem,
  DateTime date, {
  FoodItem? existingItem,
}) {
  final controller = TextEditingController(
    text:
        existingItem?.servingSize.toString() ??
        (baseItem.servingUnit == FoodUnit.servings
            ? "1"
            : baseItem.servingSize.toString()),
  );
  FoodUnit selectedUnit = existingItem?.servingUnit ?? baseItem.servingUnit;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          existingItem == null
              ? "Add ${baseItem.name}"
              : "Edit ${baseItem.name}",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            DropdownButton<FoodUnit>(
              value: selectedUnit,
              isExpanded: true,
              items: FoodUnit.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                  .toList(),
              onChanged: (v) => setDialogState(() => selectedUnit = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(controller.text) ?? 0;
              if (amt > 0) {
                double mult = (selectedUnit == FoodUnit.servings)
                    ? amt
                    : (amt / baseItem.servingSize);
                final state = context.read<AppState>();

                if (existingItem == null) {
                  // Adding new entry - preserve pantry item ID for inventory tracking
                  await state.logFoodToDate(
                    date,
                    FoodItem(
                      id: baseItem
                          .id, // Preserve ID from pantry for inventory tracking
                      name: baseItem.name,
                      servingSize: amt,
                      servingUnit: selectedUnit,
                      calories: baseItem.calories * mult,
                      protein: baseItem.protein * mult,
                      fat: baseItem.fat * mult,
                      carbs: baseItem.carbs * mult,
                      sodium: baseItem.sodium * mult,
                      fiber: baseItem.fiber * mult,
                      price: baseItem.price * mult,
                    ),
                  );
                } else {
                  // Editing existing entry
                  final pantryItem = state.pantry.firstWhere(
                    (p) => p.name == existingItem.name,
                    orElse: () => baseItem,
                  );

                  await state.updateDiaryEntry(
                    date,
                    existingItem.id,
                    FoodItem(
                      id: existingItem.id,
                      name: pantryItem.name,
                      servingUnit: selectedUnit,
                      servingSize: amt,
                      calories: pantryItem.calories * mult,
                      protein: pantryItem.protein * mult,
                      fat: pantryItem.fat * mult,
                      carbs: pantryItem.carbs * mult,
                      sodium: pantryItem.sodium * mult,
                      fiber: pantryItem.fiber * mult,
                      price: pantryItem.price * mult,
                    ),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(existingItem == null ? "Log Entry" : "Update"),
          ),
        ],
      ),
    ),
  );
}
