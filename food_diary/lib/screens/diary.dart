// lib/screens/diary.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';
import '../services/database_service.dart';

class Diary extends StatelessWidget {
  const Diary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ValueListenableBuilder listens to the Hive box for any changes
      body: ValueListenableBuilder(
        valueListenable: Hive.box(DatabaseService.boxName).listenable(),
        builder: (context, Box box, _) {
          final items = box.values.toList();

          if (items.isEmpty) {
            return Center(
              child: Text('No items saved yet.', style: TextStyle(fontSize: 24))
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = FoodProduct.fromMap(items[index]);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(product.brand),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => box.deleteAt(index),
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