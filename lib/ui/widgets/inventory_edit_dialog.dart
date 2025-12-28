import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/food_unit.dart';
import '../../providers/app_state.dart';

/// Shows a dialog to edit inventory quantity for a pantry item
Future<void> showInventoryEditDialog(
  BuildContext context,
  String pantryItemId,
  double currentQuantity,
  FoodUnit currentUnit,
  String itemName,
) async {
  return showDialog(
    context: context,
    builder: (context) => _InventoryEditDialog(
      pantryItemId: pantryItemId,
      currentQuantity: currentQuantity,
      currentUnit: currentUnit,
      itemName: itemName,
    ),
  );
}

class _InventoryEditDialog extends StatefulWidget {
  final String pantryItemId;
  final double currentQuantity;
  final FoodUnit currentUnit;
  final String itemName;

  const _InventoryEditDialog({
    required this.pantryItemId,
    required this.currentQuantity,
    required this.currentUnit,
    required this.itemName,
  });

  @override
  State<_InventoryEditDialog> createState() => _InventoryEditDialogState();
}

class _InventoryEditDialogState extends State<_InventoryEditDialog> {
  late TextEditingController _controller;
  late FoodUnit _selectedUnit;
  bool _isAdding = true; // true = add to existing, false = set absolute

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selectedUnit = widget.currentUnit;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Inventory: ${widget.itemName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current: ${widget.currentQuantity.toStringAsFixed(1)} ${widget.currentUnit.name}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: _isAdding ? 'Amount to add' : 'New total',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FoodUnit>(
            initialValue: _selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            items: FoodUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedUnit = v!),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Set Total'),
                icon: Icon(Icons.edit),
              ),
              ButtonSegment(
                value: true,
                label: Text('Add More'),
                icon: Icon(Icons.add),
              ),
            ],
            selected: {_isAdding},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isAdding = newSelection.first;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(_controller.text) ?? 0;
            if (amount >= 0) {
              final state = context.read<AppState>();

              // Calculate new total based on mode
              final newTotal = _isAdding
                  ? widget.currentQuantity + amount
                  : amount;

              await state.updateInventoryQuantity(
                widget.pantryItemId,
                newTotal,
                _selectedUnit,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
