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
        String target = _selectedIndex == 1 ? 'pantry' : 'diary';
        FoodDialogs.showProductResult(context, product, target: target);
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
        backgroundColor: isError ? Colors.redAccent : Colors.blueGrey[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSearchDialog() {
    final dbService = DatabaseService();
    List<FoodProduct> rawProducts = dbService.getAllProducts();

    if (rawProducts.isEmpty) {
      _showSnack("No products saved yet.", isError: true);
      return;
    }

    // Deduplicate by name and brand
    final Map<String, FoodProduct> uniqueMap = {};
    for (var p in rawProducts) {
      final key = "${p.name.toLowerCase()}|${p.brand.toLowerCase()}";
      // Keep existing or replace? Let's just keep the first one encountered
      // or the one with most info? For now, first is fine.
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = p;
      }
    }
    final allProducts = uniqueMap.values.toList();

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
                                    String target = _selectedIndex == 1
                                        ? 'pantry'
                                        : 'diary';
                                    FoodDialogs.showProductResult(
                                      context,
                                      product,
                                      target: target,
                                    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildSpeedDial(theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSpeedDial(ThemeData theme) {
    String target = _selectedIndex == 1 ? 'pantry' : 'diary';

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
          onTap: () => FoodDialogs.showManualEntry(context, target: target),
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
