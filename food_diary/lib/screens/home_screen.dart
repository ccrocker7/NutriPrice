import 'package:flutter/material.dart';

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

  // --- 3. The Centered Product Dialog ---
  void _showProductDialog(FoodProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          surfaceTintColor: Theme.of(context).colorScheme.primary,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                product.brand,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text("${product.calories ?? '---'} kcal / 100g", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss")),
            FilledButton(
              onPressed: () async {
                final db = DatabaseService();
                
                // We create a new FoodProduct instance or use the existing one
                // Hive will store it as a Map thanks to our service
                await db.saveProduct(product);
                
                if (mounted) {
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Saved to your history!"),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Save Product"),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onScanButtonPressed,
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, size: 30),
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