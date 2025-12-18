import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          secondary: Colors.orangeAccent,
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

  // Function to handle the scan button press
  Future<void> _onScanButtonPressed() async {
    // Navigate to the scanner screen and await the result
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    // If we got a code back (user didn't just back out), show it
    if (scannedCode != null && mounted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Product Found: $scannedCode'),
      //     backgroundColor: Colors.teal,
      //     action: SnackBarAction(
      //       label: 'VIEW',
      //       textColor: Colors.white,
      //       onPressed: () {
      //         // TODO: Navigate to product details page using scannedCode
      //         debugPrint("Navigating to details for $scannedCode");
      //       },
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriPrice'),
        centerTitle: true,
        backgroundColor: colorScheme.inversePrimary,
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
        color: colorScheme.surfaceContainerHighest,
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
            _buildTabItem(icon: Icons.person_outline, index: 2, label: "History"),
            _buildTabItem(icon: Icons.menu, index: 3, label: "Settings"),
          ],
        ),
      ),
    );
  }

  // A helper widget to build the bottom bar icons consistently
  Widget _buildTabItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
             Text(label, style: TextStyle(color: color, fontSize: 12))
          ],
        ),
      ),
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