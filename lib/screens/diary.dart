import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_product.dart';
import '../services/database_service.dart';
import '../widgets/food_dialogs.dart';

import 'package:intl/intl.dart';

class Diary extends StatefulWidget {
  const Diary({super.key});

  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSameDay(DateTime? d1, DateTime d2) {
    if (d1 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Diary List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box(
                DatabaseService.diaryBoxName,
              ).listenable(),
              builder: (context, Box box, _) {
                // Filter items by selected date
                // Note: We need to pass the index of the original item for updates/deletes
                // So we map to a structure preserving index, or just look up dynamically.
                // Keeping it simple: We need the key (index) to update/delete.
                // Hive box indices are stable if we don't compact? Actually deleteAt changes indices.
                // Best to iterate deeply or use Keys if possible.
                // Given current implementation uses `index` (int), we must be careful.
                // Current `items` is list of values. `box.getAt(index)` works.
                // If we filter, we lose the original index.

                // Better approach: Create a list of {index, data} objects.
                final dayItems = <Map<String, dynamic>>[];

                for (int i = 0; i < box.length; i++) {
                  final raw = box.getAt(i) as Map<dynamic, dynamic>;
                  final product = FoodProduct.fromMap(raw);
                  if (_isSameDay(product.dateAdded, _selectedDate)) {
                    dayItems.add({'index': i, 'product': product});
                  }
                }

                if (dayItems.isEmpty) {
                  return Center(
                    child: Text(
                      'No entries for ${DateFormat('MM/dd').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dayItems.length,
                  itemBuilder: (context, i) {
                    final entry = dayItems[i];
                    final index = entry['index'] as int;
                    final product = entry['product'] as FoodProduct;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.brand} • ${product.quantity ?? 1} ${product.unit ?? "Serving"}${product.price != null ? " • \$${product.price}" : ""}',
                        ),
                        onTap: () => FoodDialogs.showEditProduct(
                          context: context,
                          product: product,
                          onSave: (newProduct) =>
                              DatabaseService.updateDiaryEntry(
                                index,
                                newProduct,
                              ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              DatabaseService().deleteDiaryEntry(index),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
