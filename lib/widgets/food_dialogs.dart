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

  static void showManualEntry(BuildContext context, {String target = 'diary'}) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    final sodiumCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: "1");
    final selectedUnit = ValueNotifier<String>("Serving");

    // Helper to auto-populate price from pantry
    void applyPantryPrice() {
      if (target != 'diary') return;
      // Search pantry by name only if brand is "Manual Entry" or name matches
      final match = DatabaseService.findPantryItem(nameCtrl.text, null);
      if (match != null && match.unitPrice != null) {
        double unitPrice = double.tryParse(match.unitPrice!) ?? 0;
        double qty = double.tryParse(quantityCtrl.text) ?? 1;
        priceCtrl.text = (unitPrice * qty).toStringAsFixed(2);
      }
    }

    nameCtrl.addListener(applyPantryPrice);
    quantityCtrl.addListener(applyPantryPrice);

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
                      child: ValueListenableBuilder<String>(
                        valueListenable: selectedUnit,
                        builder: (context, unit, _) =>
                            DropdownButtonFormField<String>(
                              initialValue: unit,
                              decoration: const InputDecoration(
                                labelText: "Unit",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                if (val != null) selectedUnit.value = val;
                              },
                              items: _units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  calCtrl,
                  "Calories",
                  "kcal",
                  Icons.bolt,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                _buildField(
                  priceCtrl,
                  target == 'pantry' ? "Purchase Price" : "Price",
                  "\$",
                  Icons.attach_money,
                  width: double.infinity,
                ),
                const Divider(height: 32),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    quantityCtrl,
                    selectedUnit,
                    calCtrl,
                    proteinCtrl,
                    fatCtrl,
                    carbsCtrl,
                    fiberCtrl,
                    sodiumCtrl,
                  ]),
                  builder: (context, _) {
                    double qty = double.tryParse(quantityCtrl.text) ?? 1.0;
                    String total(TextEditingController ctrl) {
                      double val = double.tryParse(ctrl.text) ?? 0;
                      return (val * qty).toStringAsFixed(1);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (calCtrl.text.isNotEmpty ||
                            proteinCtrl.text.isNotEmpty ||
                            fatCtrl.text.isNotEmpty ||
                            carbsCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              "Total Logged ($qty ${selectedUnit.value}):",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
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
                          ],
                        ),
                        if (calCtrl.text.isNotEmpty ||
                            proteinCtrl.text.isNotEmpty ||
                            fatCtrl.text.isNotEmpty ||
                            carbsCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Calories: ${total(calCtrl)} kcal",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "P: ${total(proteinCtrl)}g  F: ${total(fatCtrl)}g  C: ${total(carbsCtrl)}g",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameCtrl.removeListener(applyPantryPrice);
                quantityCtrl.removeListener(applyPantryPrice);
                Navigator.pop(dialogCtx);
              },
              child: const Text("Cancel"),
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
                  unit: selectedUnit.value,
                  // Preserve serving info if we matched a pantry item earlier
                  // (Currently manual entry doesn't track this, but good for consistency)
                );

                // Save to master product list for search history
                await DatabaseService.saveProduct(product);

                if (target == 'pantry') {
                  await DatabaseService.addToPantry(product);
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Added to Pantry"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(
                        bottom: 100,
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueGrey[800],
                    ),
                  );
                } else {
                  double qtyToMove = double.tryParse(quantityCtrl.text) ?? 1.0;
                  await DatabaseService.moveFromPantryToDiary(
                    product,
                    qtyToMove,
                  );
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Added to Diary"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(
                        bottom: 100,
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueGrey[800],
                    ),
                  );
                }
                nameCtrl.removeListener(applyPantryPrice);
                quantityCtrl.removeListener(applyPantryPrice);
              },
              child: Text(
                target == 'pantry' ? "Add to Pantry" : "Add to Diary",
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showProductResult(
    BuildContext context,
    FoodProduct product, {
    String target = 'diary',
  }) {
    final priceController = TextEditingController();
    final quantityCtrl = TextEditingController(text: "1");
    final selectedUnit = ValueNotifier<String>(product.unit ?? "Serving");

    // Helper to auto-populate price from pantry with unit conversion
    void applyPantryPrice() {
      if (target != 'diary') return;
      final match = DatabaseService.findPantryItem(product.name, product.brand);
      if (match != null && match.unitPrice != null) {
        double pantryUnitPrice = double.tryParse(match.unitPrice!) ?? 0;
        double enteredQty = double.tryParse(quantityCtrl.text) ?? 1;

        // Conversion logic: Convert everything to "Servings" to find ratio
        String dialogUnit = selectedUnit.value;
        String pantryUnit = match.unit ?? "Serving";

        double getMultiplier(String unit) {
          if (unit == 'Serving') return 1.0;
          if (product.servingQuantity != null && product.servingQuantity! > 0) {
            // How many servings in 1 unit of this? (e.g. 1g = 1/servingQty servings)
            return 1.0 / product.servingQuantity!;
          }
          return 1.0;
        }

        double dialogServings = enteredQty * getMultiplier(dialogUnit);
        double pantryServingsPerUnit = 1.0 * getMultiplier(pantryUnit);

        double pantryUnitsEquivalent = dialogServings / pantryServingsPerUnit;
        priceController.text = (pantryUnitPrice * pantryUnitsEquivalent)
            .toStringAsFixed(2);
      }
    }

    quantityCtrl.addListener(applyPantryPrice);
    selectedUnit.addListener(applyPantryPrice);

    // Initial check
    applyPantryPrice();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.brand, style: TextStyle(color: Colors.grey[400])),
                if (product.servingQuantity != null &&
                    product.servingUnit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Serving Size: ${product.servingQuantity} ${product.servingUnit}",
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Divider(height: 24),
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
                      child: ValueListenableBuilder<String>(
                        valueListenable: selectedUnit,
                        builder: (context, currentUnit, _) =>
                            DropdownButtonFormField<String>(
                              initialValue: currentUnit,
                              decoration: const InputDecoration(
                                labelText: "Unit",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                if (val != null) selectedUnit.value = val;
                              },
                              items: _units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                            ),
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([quantityCtrl, selectedUnit]),
                  builder: (context, _) {
                    double enteredQty =
                        double.tryParse(quantityCtrl.text) ?? 1.0;
                    double multiplier = enteredQty;

                    // If unit is weight/volume and we have serving info, calculate ratio
                    if (selectedUnit.value != 'Serving' &&
                        product.servingQuantity != null &&
                        product.servingQuantity! > 0) {
                      multiplier = enteredQty / product.servingQuantity!;
                    }

                    String scale(String? val) {
                      if (val == null) return "0";
                      double v = double.tryParse(val) ?? 0;
                      return (v * multiplier).toStringAsFixed(1);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          priceController,
                          target == 'pantry' ? "Purchase Price" : "Price",
                          "\$",
                          Icons.attach_money,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 16),
                        if (product.calories != null)
                          _buildDetailRow(
                            "Calories",
                            "${scale(product.calories)} kcal",
                          ),
                        if (product.protein != null)
                          _buildDetailRow(
                            "Protein",
                            "${scale(product.protein)} g",
                          ),
                        if (product.fat != null)
                          _buildDetailRow("Fat", "${scale(product.fat)} g"),
                        if (product.carbs != null)
                          _buildDetailRow("Carbs", "${scale(product.carbs)} g"),
                        if (product.fiber != null)
                          _buildDetailRow("Fiber", "${scale(product.fiber)} g"),
                        if (product.sodium != null)
                          _buildDetailRow(
                            "Sodium",
                            "${scale(product.sodium)} mg",
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                quantityCtrl.removeListener(applyPantryPrice);
                selectedUnit.removeListener(applyPantryPrice);
                Navigator.pop(dialogCtx);
              },
              child: const Text("Dismiss"),
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
                  unit: selectedUnit.value,
                  servingQuantity: product.servingQuantity,
                  servingUnit: product.servingUnit,
                );

                // Always save to master product list for search history
                await DatabaseService.saveProduct(finalProduct);

                if (target == 'pantry') {
                  await DatabaseService.saveProduct(finalProduct);
                  await DatabaseService.addToPantry(finalProduct);
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Added to Pantry"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(
                        bottom: 100,
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueGrey[800],
                    ),
                  );
                } else {
                  double qtyToMove = double.tryParse(quantityCtrl.text) ?? 1.0;
                  await DatabaseService.moveFromPantryToDiary(
                    finalProduct,
                    qtyToMove,
                  );
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Added to Diary"),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(
                        bottom: 100,
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueGrey[800],
                    ),
                  );
                }
                quantityCtrl.removeListener(applyPantryPrice);
                selectedUnit.removeListener(applyPantryPrice);
              },
              child: Text(
                target == 'pantry' ? "Add to Pantry" : "Add to Diary",
              ),
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
          content: SingleChildScrollView(
            child: Column(
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
                        value: selectedUnit,
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
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: quantityCtrl,
                  builder: (context, _) {
                    // Create a copy to use its scaling logic
                    final preview = FoodProduct(
                      name: product.name,
                      brand: product.brand,
                      calories: product.calories,
                      fat: product.fat,
                      carbs: product.carbs,
                      fiber: product.fiber,
                      sodium: product.sodium,
                      protein: product.protein,
                      quantity: quantityCtrl.text,
                      unit: selectedUnit,
                      servingQuantity: product.servingQuantity,
                      servingUnit: product.servingUnit,
                    );

                    double multiplier = preview.getNutrientMultiplier();

                    String scale(String? val) {
                      if (val == null) return "0";
                      double v = double.tryParse(val) ?? 0;
                      return (v * multiplier).toStringAsFixed(1);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.calories != null)
                          _buildDetailRow(
                            "Calories",
                            "${scale(product.calories)} kcal",
                          ),
                        if (product.protein != null)
                          _buildDetailRow(
                            "Protein",
                            "${scale(product.protein)} g",
                          ),
                        if (product.fat != null)
                          _buildDetailRow("Fat", "${scale(product.fat)} g"),
                        if (product.carbs != null)
                          _buildDetailRow("Carbs", "${scale(product.carbs)} g"),
                        if (product.fiber != null)
                          _buildDetailRow("Fiber", "${scale(product.fiber)} g"),
                        if (product.sodium != null)
                          _buildDetailRow(
                            "Sodium",
                            "${scale(product.sodium)} mg",
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
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
                  servingQuantity: product.servingQuantity,
                  servingUnit: product.servingUnit,
                );

                await onSave(updatedProduct);
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

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
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
