import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/services/unit_converter.dart';
import '../widgets/inventory_edit_dialog.dart';
import 'add_food_screen.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.pantry
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search Pantry...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (c, i) {
                final item = items[i];
                final isLow =
                    item.quantityRemaining > 0 &&
                    item.quantityRemaining < item.servingSize * 3;
                final isEmpty = item.quantityRemaining <= 0;

                return Dismissible(
                  key: Key(item.id),
                  onDismissed: (_) async =>
                      await state.deletePantryItem(item.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.inventory_2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (isEmpty || isLow)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isEmpty ? Colors.red : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: const Icon(
                                Icons.warning,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.servingSize.toStringAsFixed(0)} ${item.servingUnit.name} • '
                      '${UnitConverter.formatQuantity(item.quantityRemaining, item.inventoryUnit)} remaining',
                      style: TextStyle(
                        color: isEmpty
                            ? Colors.red
                            : isLow
                            ? Colors.orange
                            : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Edit Inventory',
                          onPressed: () => showInventoryEditDialog(
                            context,
                            item.id,
                            item.quantityRemaining,
                            item.inventoryUnit,
                            item.name,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => AddFoodScreen(existingItem: item),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
