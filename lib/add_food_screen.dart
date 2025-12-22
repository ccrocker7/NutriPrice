import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodItem? existingItem;
  final bool isLoggingOnly; // New flag

  const AddFoodScreen({super.key, this.existingItem, this.isLoggingOnly = false});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _calController;
  late TextEditingController _fatController;
  late TextEditingController _sodiumController;
  late TextEditingController _carbsController;
  late TextEditingController _fiberController;
  late TextEditingController _proteinController;
  late TextEditingController _priceController;
  late TextEditingController _totalServingsController;
  late TextEditingController _servingSizeController;
  late FoodUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? "");
    _calController = TextEditingController(text: item?.calories.toString() ?? "");
    _fatController = TextEditingController(text: item?.fat.toString() ?? "");
    _sodiumController = TextEditingController(text: item?.sodium.toString() ?? "");
    _carbsController = TextEditingController(text: item?.carbs.toString() ?? "");
    _fiberController = TextEditingController(text: item?.fiber.toString() ?? "");
    _proteinController = TextEditingController(text: item?.protein.toString() ?? "");
    _priceController = TextEditingController(text: item != null ? item.price.toString() : ""); 
    _totalServingsController = TextEditingController(text: item != null ? "1" : ""); 
    _servingSizeController = TextEditingController(text: item?.servingSize.toString() ?? "");
    _selectedUnit = item?.servingUnit ?? FoodUnit.grams;
  }

  void _save() {
  if (_formKey.currentState!.validate()) {
    // 1. Ensure we don't divide by zero
    final totalServings = double.tryParse(_totalServingsController.text) ?? 1;
    final totalPrice = double.tryParse(_priceController.text) ?? 0;
    final pricePerServing = totalPrice / (totalServings > 0 ? totalServings : 1);

    // 2. Build the item
    final newItem = FoodItem(
      // Keep the ID if we are editing, otherwise it's a new UUID
      id: widget.existingItem?.id ?? const Uuid().v4(), 
      name: _nameController.text,
      calories: double.parse(_calController.text),
      fat: double.parse(_fatController.text),
      sodium: double.parse(_sodiumController.text),
      carbs: double.parse(_carbsController.text),
      fiber: double.parse(_fiberController.text),
      protein: double.parse(_proteinController.text),
      price: pricePerServing,
      servingSize: double.parse(_servingSizeController.text),
      servingUnit: _selectedUnit,
    );

    final state = context.read<AppState>();
    
    // 3. Logic check: If it's a quick log, it goes to Diary. 
    // Otherwise, if it's NOT in the pantry list yet, add it.
    if (widget.isLoggingOnly) {
      state.logFoodToDate(state.selectedDate, newItem);
    } else {
      // Check if this specific ID already exists in the pantry
      final exists = state.pantry.any((item) => item.id == newItem.id);
      if (exists) {
        state.updatePantryItem(newItem);
      } else {
        state.addToPantry(newItem);
      }
    }
    
    Navigator.pop(context);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLoggingOnly ? "Quick Log Entry" : (widget.existingItem == null ? "New Pantry Item" : "Edit Pantry Item"))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Food Name")),
              _numField(_calController, "Calories"),
              _numField(_fatController, "Fat (g)"),
              _numField(_sodiumController, "Sodium (mg)"),
              _numField(_carbsController, "Carbs (g)"),
              _numField(_fiberController, "Fiber (g)"),
              _numField(_proteinController, "Protein (g)"),
              Row(
                children: [
                  Expanded(child: _numField(_servingSizeController, "Serving Size")),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<FoodUnit>(
                      initialValue: _selectedUnit,
                      items: FoodUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _numField(_priceController, "Total Price (\$)")),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(_totalServingsController, "Total Servings")),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save, 
                child: Text(widget.isLoggingOnly ? "Log to Diary" : "Save to Pantry")
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (v) => double.tryParse(v ?? '') == null ? "Required" : null,
    );
  }
}