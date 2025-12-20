import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../services/product_service.dart';
import '../services/database_service.dart';
import '../models/food_product.dart';
import '../widgets/food_dialogs.dart'; // Our new file
import '../widgets/weight_dialog.dart';

// Screens
import 'scanner_screen.dart';
import 'pantry.dart';
import 'diary.dart';
import 'history.dart';
import 'settings.dart';

class NutriPriceHomeScreen extends StatefulWidget {
  const NutriPriceHomeScreen({super.key});

  @override
  State<NutriPriceHomeScreen> createState() => _NutriPriceHomeScreenState();
}

class _NutriPriceHomeScreenState extends State<NutriPriceHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [Diary(), Pantry(), History(), Settings()];

  void _onScanButtonPressed() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (code == null || !mounted) return;

    _showLoading();

    try {
      final product = await ProductService()
          .fetchProductByBarcode(code)
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (product != null) {
        FoodDialogs.showProductResult(context, product);
      } else {
        _showSnack("Product not found.", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack("Connection error.", isError: true);
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSearchDialog() {
    final dbService = DatabaseService();
    final allProducts = dbService.getAllProducts();

    if (allProducts.isEmpty) {
      _showSnack("No products saved yet.", isError: true);
      return;
    }

    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          // Filter products based on search query
          final filteredProducts = allProducts.where((product) {
            final query = searchController.text.toLowerCase();
            return product.name.toLowerCase().contains(query) ||
                product.brand.toLowerCase().contains(query);
          }).toList();

          return AlertDialog(
            title: const Text("Search Products"),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name or brand...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              "No products found",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.restaurant_menu),
                                  title: Text(product.name),
                                  subtitle: Text(product.brand),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (product.calories != null)
                                        Text(
                                          '${product.calories} kcal',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                "Delete Product",
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete '${product.name}'?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    await DatabaseService.deleteProduct(
                                                      product,
                                                    );
                                                    // Update local list to refresh UI
                                                    allProducts.remove(product);
                                                    setState(() {});
                                                  },
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    _showProductDetails(product);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductDetails(FoodProduct product) {
    final quantityCtrl = TextEditingController(text: "1");
    // Default to strict 'Serving' matching or fallback
    String selectedUnit = product.unit ?? "Serving";

    // Ensure the default unit is in our list, otherwise default to Serving
    const validUnits = ['Serving', 'g', 'mL', 'oz', 'lb', 'cup', 'tbsp', 'tsp'];
    if (!validUnits.contains(selectedUnit)) {
      selectedUnit = "Serving";
    }

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
                        items: validUnits
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (product.calories != null)
                  _buildDetailRow("Calories", "${product.calories} kcal"),
                if (product.protein != null)
                  _buildDetailRow("Protein", "${product.protein} g"),
                if (product.fat != null)
                  _buildDetailRow("Fat", "${product.fat} g"),
                if (product.carbs != null)
                  _buildDetailRow("Carbs", "${product.carbs} g"),
                if (product.fiber != null)
                  _buildDetailRow("Fiber", "${product.fiber} g"),
                if (product.sodium != null)
                  _buildDetailRow("Sodium", "${product.sodium} mg"),
                if (product.price != null)
                  _buildDetailRow("Price", "\$${product.price}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Close"),
            ),
            FilledButton.tonal(
              onPressed: () async {
                // Update product with user-entered quantity
                final newProduct = FoodProduct(
                  name: product.name,
                  brand: product.brand,
                  calories: product.calories,
                  fat: product.fat,
                  carbs: product.carbs,
                  fiber: product.fiber,
                  sodium: product.sodium,
                  protein: product.protein,
                  price: product.price,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                await DatabaseService.addToPantry(newProduct);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                _showSnack("Added to Pantry");
              },
              child: const Text("Add to Pantry"),
            ),
            FilledButton(
              onPressed: () async {
                // Update product with user-entered quantity
                final newProduct = FoodProduct(
                  name: product.name,
                  brand: product.brand,
                  calories: product.calories,
                  fat: product.fat,
                  carbs: product.carbs,
                  fiber: product.fiber,
                  sodium: product.sodium,
                  protein: product.protein,
                  price: product.price,
                  quantity: quantityCtrl.text,
                  unit: selectedUnit,
                );
                // logic: if it exists in pantry, deduct parsing the double quantity
                double qtyToMove = double.tryParse(quantityCtrl.text) ?? 1.0;
                await DatabaseService.moveFromPantryToDiary(
                  newProduct,
                  qtyToMove,
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                _showSnack("Added to Diary");
              },
              child: const Text("Add to Diary"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('NutriPrice'), centerTitle: true),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSpeedDial(theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSpeedDial(ThemeData theme) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: theme.colorScheme.secondary,
      overlayOpacity: 0.5,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.search),
          label: 'Search Products',
          onTap: _showSearchDialog,
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: 'Manual Entry',
          onTap: () => FoodDialogs.showManualEntry(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan Barcode',
          onTap: _onScanButtonPressed,
        ),
        SpeedDialChild(
          child: const Icon(Icons.monitor_weight),
          label: 'Log Weight',
          onTap: () => WeightDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.book, 0),
          _navItem(Icons.kitchen, 1),
          const SizedBox(width: 48),
          _navItem(Icons.history, 2),
          _navItem(Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
      ),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}
