import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../providers/app_state.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_unit.dart';
import '../widgets/weight_dialog.dart';
import '../widgets/pantry_picker.dart';
import '../widgets/amount_dialog.dart';
import 'diary_page.dart';
import 'pantry_page.dart';
import 'settings_page.dart';
import 'barcode_scanner_page.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = const [DiaryPage(), PantryPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Pantry'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? null
          : SpeedDial(
              icon: Icons.add,
              backgroundColor: Colors.green,
              children: _selectedIndex == 0
                  ? [
                      SpeedDialChild(
                        child: const Icon(Icons.monitor_weight),
                        label: 'Log Weight',
                        onTap: () =>
                            showWeightDialog(context, state.selectedDate),
                      ),
                      SpeedDialChild(
                        child: const Icon(Icons.inventory_2),
                        label: 'From Pantry',
                        onTap: () => _handlePantryPicker(context, state),
                      ),
                      SpeedDialChild(
                        child: const Icon(Icons.edit_note),
                        label: 'Quick Log',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const AddFoodScreen(isLoggingOnly: true),
                          ),
                        ),
                      ),
                    ]
                  : [
                      SpeedDialChild(
                        child: const Icon(Icons.qr_code_scanner),
                        label: 'Scan Barcode',
                        onTap: () => _scanBarcode(context),
                      ),
                      SpeedDialChild(
                        child: const Icon(Icons.add_box),
                        label: 'Manual Add',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const AddFoodScreen(),
                          ),
                        ),
                      ),
                    ],
            ),
    );
  }

  void _handlePantryPicker(BuildContext context, AppState state) async {
    final selectedItem = await showPantryPicker(context, state.pantry);
    if (selectedItem != null && context.mounted) {
      showAmountDialog(context, selectedItem, state.selectedDate);
    }
  }

  void _scanBarcode(BuildContext context) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (c) => const BarcodeScannerPage()),
    );
    if (code != null && context.mounted) {
      _handleBarcode(context, code);
    }
  }

  Future<void> _handleBarcode(BuildContext context, String code) async {
    showDialog(
      context: context,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final r = await http.get(
      Uri.parse('https://world.openfoodfacts.org/api/v2/product/$code.json'),
    );

    if (context.mounted) Navigator.pop(context);

    final data = json.decode(r.body);
    if (data['status'] == 1) {
      final p = data['product'];
      final n = p['nutriments'] ?? {};
      final item = FoodItem(
        id: const Uuid().v4(),
        name: p['product_name'] ?? "Unknown",
        calories: (n['energy-kcal_serving'] ?? 0).toDouble(),
        fat: (n['fat_serving'] ?? 0).toDouble(),
        sodium: (n['sodium_serving'] ?? 0).toDouble() * 1000,
        carbs: (n['carbohydrates_serving'] ?? 0).toDouble(),
        fiber: (n['fiber_serving'] ?? 0).toDouble(),
        protein: (n['proteins_serving'] ?? 0).toDouble(),
        price: 0.0,
        servingSize: (p['serving_quantity'] ?? 0).toDouble(),
        servingUnit: (p['serving_quantity_unit'] == 'oz')
            ? FoodUnit.ounces
            : FoodUnit.grams,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => AddFoodScreen(existingItem: item)),
        );
      }
    }
  }
}
