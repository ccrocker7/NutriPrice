import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../services/database_service.dart';

class FoodDialogs {
  static const List<String> _units = [
    'Serving',
    'g',
    'mL',
    'oz',
    'lb',
    'cup',
    'tbsp',
    'tsp',
  ];

  static void showManualEntry(BuildContext context) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    final sodiumCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: "1");
    String selectedUnit = "Serving";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Manual Entry"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Qty",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: "Unit",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedUnit = val);
                        },
                        items: _units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(calCtrl, "Calories", "kcal", Icons.bolt),
                const Divider(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildField(
                      proteinCtrl,
                      "Protein",
                      "g",
                      Icons.fitness_center,
                      width: 110,
                    ),
                    _buildField(
                      fatCtrl,
                      "Fat",
                      "g",
                      Icons.water_drop,
                      width: 110,
                    ),
                    _buildField(
                      carbsCtrl,
                      "Carbs",
                      "g",
                      Icons.bakery_dining,
                      width: 110,
                    ),
                    _buildField(
                      fiberCtrl,
                      "Fiber",
                      "g",
                      Icons.grass,
                      width: 110,
                    ),
                    _buildField(
                      sodiumCtrl,
                      "Sodium",
                      "mg",
                      Icons.science,
                      width: 110,
                    ),
                    _buildField(
                      priceCtrl,
                      "Price",
                      "\$",
                      Icons.attach_money,
                      width: 110,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            FilledButton.tonal(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final product = FoodProduct(
                  name: nameCtrl.text,
                  brand: "Manual Entry",
                  calories: calCtrl.text.isEmpty ? null : calCtrl.text,
                  protein: proteinCtrl.text.isEmpty ? null : proteinCtrl.text,
                  fat: fatCtrl.text.isEmpty ? null : fatCtrl.text,
                  carbs: carbsCtrl.text.isEmpty ? null : carbsCtrl.text,
                  fiber: fiberCtrl.text.isEmpty ? null : fiberCtrl.text,
                  sodium: sodiumCtrl.text.isEmpty ? null : sodiumCtrl.text,
                  price: priceCtrl.text.isEmpty ? null : priceCtrl.text,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                await DatabaseService.saveProduct(product);
                await DatabaseService.addToPantry(product);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Added to Pantry")),
                );
              },
              child: const Text("Add to Pantry"),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final product = FoodProduct(
                  name: nameCtrl.text,
                  brand: "Manual Entry",
                  calories: calCtrl.text.isEmpty ? null : calCtrl.text,
                  protein: proteinCtrl.text.isEmpty ? null : proteinCtrl.text,
                  fat: fatCtrl.text.isEmpty ? null : fatCtrl.text,
                  carbs: carbsCtrl.text.isEmpty ? null : carbsCtrl.text,
                  fiber: fiberCtrl.text.isEmpty ? null : fiberCtrl.text,
                  sodium: sodiumCtrl.text.isEmpty ? null : sodiumCtrl.text,
                  price: priceCtrl.text.isEmpty ? null : priceCtrl.text,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                await DatabaseService.saveProduct(product);
                await DatabaseService.addToDiary(product);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Added to Diary")));
              },
              child: const Text("Add to Diary"),
            ),
          ],
        ),
      ),
    );
  }

  static void showProductResult(BuildContext context, FoodProduct product) {
    final priceController = TextEditingController();
    final quantityCtrl = TextEditingController(text: "1");
    String selectedUnit = "Serving";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.brand, style: TextStyle(color: Colors.grey[400])),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Qty",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedUnit = val);
                      },
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Price (Optional)",
                  prefixText: "\$ ",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Dismiss"),
            ),
            FilledButton.tonal(
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
                  price: priceController.text.isEmpty
                      ? null
                      : priceController.text,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                await DatabaseService.saveProduct(finalProduct);
                await DatabaseService.addToPantry(finalProduct);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Added to Pantry")),
                );
              },
              child: const Text("Add to Pantry"),
            ),
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
                  price: priceController.text.isEmpty
                      ? null
                      : priceController.text,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                await DatabaseService.saveProduct(finalProduct);
                await DatabaseService.addToDiary(finalProduct);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Added to Diary")));
              },
              child: const Text("Add to Diary"),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditProduct({
    required BuildContext context,
    required FoodProduct product,
    required Function(FoodProduct) onSave, // Callback for specific logic
  }) {
    final priceController = TextEditingController(text: product.price);
    final quantityCtrl = TextEditingController(text: product.quantity ?? "1");
    // Default unit fallback
    String selectedUnit = product.unit ?? "Serving";
    if (!_units.contains(selectedUnit)) selectedUnit = "Serving";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edit ${product.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.brand, style: TextStyle(color: Colors.grey[400])),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Qty",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedUnit = val);
                      },
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Price",
                  prefixText: "\$ ",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                // Create updated product
                final updatedProduct = FoodProduct(
                  name: product.name,
                  brand: product.brand,
                  calories: product.calories,
                  fat: product.fat,
                  carbs: product.carbs,
                  fiber: product.fiber,
                  sodium: product.sodium,
                  protein: product.protein,
                  price: priceController.text.isEmpty
                      ? null
                      : priceController.text,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );

                // Execute the callback (e.g. update diary or pantry)
                await onSave(updatedProduct);

                // ALSO update the master product reference (price/unit sync)
                // This keeps the master list up to date with the latest price seen
                await DatabaseService.updateMasterProduct(updatedProduct);

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildField(
    TextEditingController ctrl,
    String label,
    String unit,
    IconData icon, {
    double? width,
  }) {
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
