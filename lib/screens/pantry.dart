// lib/screens/pantry.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';
import '../services/database_service.dart';
import '../widgets/food_dialogs.dart';

class Pantry extends StatelessWidget {
  const Pantry({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ValueListenableBuilder listens to the Hive box for any changes
      body: ValueListenableBuilder(
        valueListenable: Hive.box(DatabaseService.pantryBoxName).listenable(),
        builder: (context, Box box, _) {
          final items = box.values.toList();

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No items in pantry yet.',
                style: TextStyle(fontSize: 24),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final raw = items[index];
              if (raw is! Map) return const SizedBox.shrink();
              final product = FoodProduct.fromMap(raw);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.kitchen,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${product.brand}\n${product.quantity ?? 1} ${product.unit ?? "Serving"}${product.price != null ? " • \$${product.price}" : ""}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => DatabaseService().deletePantryItem(index),
                  ),
                  onTap: () => FoodDialogs.showEditProduct(
                    context: context,
                    product: product,
                    onSave: (newProduct) =>
                        DatabaseService.updatePantryItem(index, newProduct),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
