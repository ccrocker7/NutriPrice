import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../services/product_service.dart';
import '../widgets/food_dialogs.dart'; // Our new file

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
      final product = await ProductService().fetchProductByBarcode(code).timeout(const Duration(seconds: 4));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ));
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
          child: const Icon(Icons.edit),
          label: 'Manual Entry',
          onTap: () => FoodDialogs.showManualEntry(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan Barcode',
          onTap: _onScanButtonPressed,
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
      icon: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.grey),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}