import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../services/database_service.dart';

class FoodDialogs {
  static void showManualEntry(BuildContext context) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    final sodiumCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Manual Entry"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_basket),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(calCtrl, "Calories", "kcal", Icons.bolt),
              const Divider(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildField(proteinCtrl, "Protein", "g", Icons.fitness_center, width: 110),
                  _buildField(fatCtrl, "Fat", "g", Icons.water_drop, width: 110),
                  _buildField(carbsCtrl, "Carbs", "g", Icons.bakery_dining, width: 110),
                  _buildField(fiberCtrl, "Fiber", "g", Icons.grass, width: 110),
                  _buildField(sodiumCtrl, "Sodium", "mg", Icons.science, width: 110),
                  _buildField(priceCtrl, "Price", "\$", Icons.attach_money, width: 110),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final product = FoodProduct(
                name: nameCtrl.text,
                brand: "Manual Entry",
                calories: calCtrl.text,
                protein: proteinCtrl.text,
                fat: fatCtrl.text,
                carbs: carbsCtrl.text,
                fiber: fiberCtrl.text,
                sodium: sodiumCtrl.text,
                price: priceCtrl.text,
              );
              await DatabaseService.saveProduct(product);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
            },
            child: const Text("Save Entry"),
          ),
        ],
      ),
    );
  }

  static void showProductResult(BuildContext context, FoodProduct product) {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Price (Optional)",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Dismiss")),
          FilledButton(
            onPressed: () async {
              final finalProduct = FoodProduct(
                name: product.name,
                brand: product.brand,
                calories: product.calories,
                fat: product.fat,
                carbs: product.carbs,
                fiber: product.fiber,
                sodium: product.sodium,
                protein: product.protein,
                price: priceController.text,
              );
              await DatabaseService.saveProduct(finalProduct);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
            },
            child: const Text("Save to Diary"),
          ),
        ],
      ),
    );
  }

  static Widget _buildField(TextEditingController ctrl, String label, String unit, IconData icon, {double? width}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}