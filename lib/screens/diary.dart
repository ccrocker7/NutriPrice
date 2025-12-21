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
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box(
                DatabaseService.diaryBoxName,
              ).listenable(),
              builder: (context, Box box, _) {
                // Filter items by selected date
                final dayItems = <Map<String, dynamic>>[];
                double totalCalories = 0;
                double totalFat = 0;
                double totalCarbs = 0;
                double totalProtein = 0;

                for (int i = 0; i < box.length; i++) {
                  final raw = box.getAt(i) as Map<dynamic, dynamic>;
                  final product = FoodProduct.fromMap(raw);
                  if (_isSameDay(product.dateAdded, _selectedDate)) {
                    dayItems.add({'index': i, 'product': product});
                    totalCalories +=
                        double.tryParse(product.calories ?? '0') ?? 0;
                    totalFat += double.tryParse(product.fat ?? '0') ?? 0;
                    totalCarbs += double.tryParse(product.carbs ?? '0') ?? 0;
                    totalProtein +=
                        double.tryParse(product.protein ?? '0') ?? 0;
                  }
                }

                return ValueListenableBuilder(
                  valueListenable: DatabaseService.getGoalsListenable(),
                  builder: (context, goalsBox, _) {
                    final calGoal =
                        goalsBox.get('calories_goal', defaultValue: 2000.0)
                            as double;
                    final proteinGoal =
                        goalsBox.get('protein_goal', defaultValue: 150.0)
                            as double;
                    final carbGoal =
                        goalsBox.get('carbs_goal', defaultValue: 200.0)
                            as double;
                    final fatGoal =
                        goalsBox.get('fat_goal', defaultValue: 65.0) as double;

                    return Column(
                      children: [
                        // Nutrition Summary Card
                        Card(
                          margin: const EdgeInsets.all(16),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  'Calories',
                                  '${totalCalories.round()}',
                                  'kcal',
                                  Colors.orange,
                                  goal: '${calGoal.round()}',
                                ),
                                _buildSummaryItem(
                                  'Protein',
                                  totalProtein.toStringAsFixed(1),
                                  'g',
                                  Colors.red,
                                  goal: proteinGoal.toStringAsFixed(1),
                                ),
                                _buildSummaryItem(
                                  'Carbs',
                                  totalCarbs.toStringAsFixed(1),
                                  'g',
                                  Colors.blue,
                                  goal: carbGoal.toStringAsFixed(1),
                                ),
                                _buildSummaryItem(
                                  'Fat',
                                  totalFat.toStringAsFixed(1),
                                  'g',
                                  Colors.green,
                                  goal: fatGoal.toStringAsFixed(1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: dayItems.isEmpty
                              ? Center(
                                  child: Text(
                                    'No entries for ${DateFormat('MM/dd').format(_selectedDate)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: dayItems.length,
                                  itemBuilder: (context, i) {
                                    final entry = dayItems[i];
                                    final index = entry['index'] as int;
                                    final product =
                                        entry['product'] as FoodProduct;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.restaurant_menu,
                                        ),
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
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => DatabaseService()
                                              .deleteDiaryEntry(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  Widget _buildSummaryItem(
    String label,
    String value,
    String unit,
    Color color, {
    String? goal,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goal != null ? '$value / $goal' : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
