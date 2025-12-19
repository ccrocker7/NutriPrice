import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

// 1. Internal Models & Services
import '../models/food_product.dart';
import '../services/database_service.dart';
import '../services/product_service.dart';

// 2. Navigation Screens
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

  // The pages corresponding to our bottom navigation tabs
  static const List<Widget> _pages = <Widget>[
    Diary(),
    Pantry(),
    History(),
    Settings(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- 1. Error Feedback ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20), // Floating above the bar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- 2. The Scanning & API Logic ---
void _onScanButtonPressed() async {
  // 1. Get the code and immediately close the scanner
  final String? scannedCode = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
  );

  // If the user cancelled, stop here
  if (scannedCode == null || !mounted) return;

  // 2. Immediate Visual Feedback (The Loader)
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 3. Parallel API call
    final service = ProductService();
    // Setting a timeout can prevent the "infinite 5-second hang"
    final product = await service.fetchProductByBarcode(scannedCode).timeout(
      const Duration(seconds: 4),
      onTimeout: () => throw Exception("Timeout"),
    );

    // 4. Clean up and Show Result
    if (mounted) Navigator.pop(context); // Close Loader

    if (product != null) {
      _showProductDialog(product);
    } else {
      _showErrorSnackBar("Product not found.");
    }
  } catch (e) {
    if (mounted) Navigator.pop(context); // Close Loader
    _showErrorSnackBar("Connection timed out. Try again!");
  }
}

void _showManualEntryDialog() {
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
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Manual Entry"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView( // Allows scrolling on smaller phones
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
              
              // Calories is the primary metric
              _buildNutrientField(calCtrl, "Calories", "kcal", Icons.bolt),
              const Divider(height: 32),
              
              // Nutrients Grid (2 per row)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildNutrientField(proteinCtrl, "Protein", "g", Icons.fitness_center, width: 110),
                  _buildNutrientField(fatCtrl, "Fat", "g", Icons.water_drop, width: 110),
                  _buildNutrientField(carbsCtrl, "Carbs", "g", Icons.bakery_dining, width: 110),
                  _buildNutrientField(fiberCtrl, "Fiber", "g", Icons.grass, width: 110),
                  _buildNutrientField(sodiumCtrl, "Sodium", "mg", Icons.science, width: 110),
                  _buildNutrientField(priceCtrl, "Price", "\$", Icons.attach_money, width: 110),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                final manualProduct = FoodProduct(
                  name: nameCtrl.text,
                  brand: "Manual Entry",
                  calories: calCtrl.text,
                  protein: proteinCtrl.text,
                  fat: fatCtrl.text,
                  carbs: carbsCtrl.text,
                  fiber: fiberCtrl.text,
                  sodium: sodiumCtrl.text,
                );

                await DatabaseService.saveProduct(manualProduct);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Center(child:Text("Added to Diary"))),
                );
              }
            },
            child: const Text("Save Entry"),
          ),
        ],
      );
    },
  );
}

// Helper widget to keep the dialog code clean
Widget _buildNutrientField(
    TextEditingController controller, String label, String unit, IconData icon, 
    {double? width}) {
  return SizedBox(
    width: width,
    child: TextField(
      controller: controller,
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

  // --- 3. The Centered Product Dialog ---
void _showProductDialog(FoodProduct product) {
  // Controller to capture the optional price
  final priceController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... existing nutrition display code ...
            
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss")),
          FilledButton(
            onPressed: () async {
              // Create a COPY of the product that includes the price
              final productWithPrice = FoodProduct(
                name: product.name,
                brand: product.brand,
                calories: product.calories,
                fat: product.fat,
                carbs: product.carbs,
                fiber: product.fiber,
                sodium: product.sodium,
                protein: product.protein,
                price: priceController.text.isNotEmpty ? priceController.text : null,
              );

              await DatabaseService.saveProduct(productWithPrice);
              
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save to Diary"),
          ),
        ],
      );
    },
  );
}

  // --- 4. The Main Layout Build ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriPrice', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            spacing: 12,
            spaceBetweenChildren: 12,
            children: [
              // 1. Manual Entry Button
              SpeedDialChild(
                child: const Icon(Icons.edit),
                backgroundColor: colorScheme.surface,
                label: 'Manual Entry',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: () => _showManualEntryDialog(),
              ),
              // 2. Scan Button
              SpeedDialChild(
                child: const Icon(Icons.qr_code_scanner),
                backgroundColor: colorScheme.surface,
                label: 'Scan Barcode',
                labelStyle: const TextStyle(fontSize: 18.0),
                onTap: _onScanButtonPressed, // Calls your existing scan logic
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(Icons.book, 0, "Diary"),
            _buildTabItem(Icons.kitchen, 1, "Pantry"),
            const SizedBox(width: 48), // Space for FAB
            _buildTabItem(Icons.history, 2, "History"),
            _buildTabItem(Icons.settings, 3, "Settings"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}