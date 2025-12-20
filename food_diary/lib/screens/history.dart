import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/weight_entry.dart';
import '../models/food_product.dart';
import '../widgets/weight_chart.dart';
import '../widgets/spending_chart.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.getWeightHistoryListenable(),
        builder: (context, weightBox, _) {
          return ValueListenableBuilder(
            valueListenable: DatabaseService.getDiaryListenable(),
            builder: (context, diaryBox, _) {
              // --- Weight Data ---
              var weightEntries = weightBox.values
                  .map((item) => WeightEntry.fromMap(item))
                  .toList();
              final thirtyDaysAgo = DateTime.now().subtract(
                const Duration(days: 30),
              );
              weightEntries = weightEntries
                  .where((e) => e.date.isAfter(thirtyDaysAgo))
                  .toList();
              weightEntries.sort((a, b) => b.date.compareTo(a.date));

              // --- Spending Data ---
              final diaryEntries = diaryBox.values
                  .map((item) => FoodProduct.fromMap(item))
                  .toList();
              // SpendingChart handles its own aggregation and 30-day filtering

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight Chart
                    const Text(
                      'Weight History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (weightEntries.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            "No weight entries in last 30 days.\nUse the + button to log your weight.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: WeightChart(entries: weightEntries),
                      ),

                    const Divider(height: 48),

                    // Spending Chart
                    const Text(
                      'Daily Spending',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (diaryEntries.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            "No diary entries found.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: SpendingChart(entries: diaryEntries),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
