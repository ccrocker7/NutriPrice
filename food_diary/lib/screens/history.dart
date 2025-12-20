import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/weight_entry.dart';
import '../widgets/weight_chart.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.getWeightHistoryListenable(),
        builder: (context, box, _) {
          // Convert box values to list
          // Convert box values to list
          var entries = box.values
              .map((item) => WeightEntry.fromMap(item))
              .toList();

          // Filter for last 30 days
          final thirtyDaysAgo = DateTime.now().subtract(
            const Duration(days: 30),
          );
          entries = entries
              .where((e) => e.date.isAfter(thirtyDaysAgo))
              .toList();

          // Sort by date, newest first
          entries.sort((a, b) => b.date.compareTo(a.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weight History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        "No weight entries yet.\nUse the + button to log your weight.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SizedBox(height: 300, child: WeightChart(entries: entries)),
                const SizedBox(height: 24),
                // Could add a list view of entries here later
              ],
            ),
          );
        },
      ),
    );
  }
}
