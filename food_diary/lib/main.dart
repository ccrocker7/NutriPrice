import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './home.dart';
import './diary.dart';
import './history.dart';
import './settings.dart';

void main() {
  runApp(const NutriPriceApp());
}

// ==================== Part 1: The App Shell ====================
class NutriPriceApp extends StatelessWidget {
  const NutriPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPrice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // A nutrition-themed color palette
        // colorScheme: ColorScheme.dark(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const NutriPriceHomeScreen(),
    );
  }
}

// ==================== Part 2: The Main Home Screen with Bottom Bar ====================
class NutriPriceHomeScreen extends StatefulWidget {
  const NutriPriceHomeScreen({super.key});

  @override
  State<NutriPriceHomeScreen> createState() => _NutriPriceHomeScreenState();
}

class _NutriPriceHomeScreenState extends State<NutriPriceHomeScreen> {
  int _selectedIndex = 0;

  // Define placeholder pages for the tabs
  static const List<Widget> _pages = <Widget>[
    Home(),
    Diary(),
    // Index 2 is skipped in UI because it's the scan button
    History(),
    Settings(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating, // Makes it pop up slightly above the bottom bar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Function to handle the scan button press
  void _onScanButtonPressed() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      // 1. Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 2. Call the API
      final service = ProductService();
      final product = await service.fetchProductByBarcode(scannedCode);

      // 3. Close the loading dialog
      if (mounted) Navigator.pop(context);

      // 4. Handle the result
      if (product != null) {
        _showProductDialog(product);
      } else {
        _showErrorSnackBar("Product not found in database.");
      }
    }
  }

  // A quick helper to show the found product
  // void _showProductModal(FoodProduct product) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => Center(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           if (product.imageUrl.isNotEmpty)
  //             Image.network(product.imageUrl, height: 150),
  //           Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  //           Text(product.brand, style: const TextStyle(fontSize: 18, color: Colors.grey)),
  //           const Divider(),
  //           Text("Calories (per 100g): ${product.calories ?? 'N/A'} kcal"),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Add to Diary"),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showProductDialog(FoodProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Rounded corners are set via the 'shape' property
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          // Use surfaceTintColor to give it that modern Material 3 look
          surfaceTintColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Prevents dialog from taking full screen
            children: [
              // 1. Product Image
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

              // 2. Product Info
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                product.brand,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              
              const Divider(height: 32),

              // 3. Nutritional Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "${product.calories ?? '---'} kcal / 100g",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss"),
            ),
            // Primary action button
            FilledButton(
              onPressed: () {
                // TODO: Add to local database
                Navigator.pop(context);
              },
              child: const Text("Save Product"),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('NutriPrice', style:TextStyle(fontWeight: FontWeight.bold) ),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.primary,
      ),
      // Using IndexedStack ensures the state of pages is kept alive
      // when switching tabs.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- The Floating Action Button (Scanner) ---
      floatingActionButton: FloatingActionButton(
        onPressed: _onScanButtonPressed,
        elevation: 4.0,
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: const CircleBorder(), // Ensures it's perfectly round for the notch
        child: const Icon(Icons.qr_code_scanner, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- The Bottom Navigation Bar ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Creates the cutout
        notchMargin: 8.0, // How much space between FAB and bar
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Left Side Icons
            _buildTabItem(icon: Icons.home, index: 0, label: "Home"),
            _buildTabItem(icon: Icons.bookmark_border, index: 1, label: "Diary"),

            // Essential: A spacer to ensure the middle is empty for the FAB
             const SizedBox(width: 60),

            // Right Side Icons
            _buildTabItem(icon: Icons.bar_chart, index: 2, label: "History"),
            _buildTabItem(icon: Icons.settings, index: 3, label: "Settings"),
          ],
        ),
      ),
    );
  }

  // A helper widget to build the bottom bar icons consistently
  Widget _buildTabItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 100, // Define the size of your circular area
        height: 100,
        child: Center(
          child: Icon(icon, color: color),
        ),
      )

    );
  }
}


// ==================== Part 3: The Dedicated Scanner Screen ====================
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Controller to manage camera (torch, switch camera, etc.)
  final MobileScannerController controller = MobileScannerController(
     detectionSpeed: DetectionSpeed.noDuplicates, // Prevents rapid-fire detection
     returnImage: false,
  );

  bool _isScanned = false;

  @override
  void dispose() {
    // Important to dispose controller to release camera resources
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent AppBar overlay
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Return null if closed
        ),
      ),
      body: Stack(
        children: [
          // The actual scanner camera view
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              // Prevent multiple scans while closing
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  debugPrint('Barcode found! ${barcode.rawValue}');
                  setState(() {
                    _isScanned = true;
                  });
                  // Vibrate for feedback (optional, requires vibration package)
                  // HapticFeedback.mediumImpact();

                  // Close screen and pass data back to home screen
                  Navigator.pop(context, barcode.rawValue);
                  break; // Stop after first detection
                }
              }
            },
          ),
          // A visual overlay box to guide the user
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
           Positioned(
            bottom: 50,
             left: 0, right: 0,
             child: const Center(
               child: Text("Align barcode within frame", style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54)),
             ),
           )
        ],
      ),
    );
  }
}


// ==================== Part 4: The Food Product Class ====================
class FoodProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String? calories; // Optional data

  FoodProduct({
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.calories,
  });

  // A factory method to turn the API's JSON into this FoodProduct object
  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return FoodProduct(
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      imageUrl: product['image_front_url'] ?? '',
      calories: product['nutriments']?['energy-kcal_100g']?.toString(),
    );
  }
}


class ProductService {
  Future<FoodProduct?> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          // Product was found!
          return FoodProduct.fromJson(data);
        }
      }
      return null; // Product not found
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}