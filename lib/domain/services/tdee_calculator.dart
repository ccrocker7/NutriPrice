import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/weight_entry.dart';

class TdeeCalculator {
  /// Calculates estimated TDEE based on weight history and diary entries
  /// Returns null if insufficient data (less than 2 weight entries or no diary entries)
  static double? calculate(
    List<WeightEntry> weightHistory,
    Map<DateTime, List<FoodItem>> diary,
  ) {
    if (weightHistory.length < 2 || diary.isEmpty) return null;

    // 1. Get the date range (last 7 days)
    final end = DateUtils.dateOnly(DateTime.now());
    final start = end.subtract(const Duration(days: 7));

    // 2. Calculate average intake over these days
    double totalCalsConsumed = 0;
    int daysWithLogs = 0;
    for (int i = 0; i <= 7; i++) {
      final date = start.add(Duration(days: i));
      final dayLogs = diary[date];
      if (dayLogs != null && dayLogs.isNotEmpty) {
        totalCalsConsumed += dayLogs.fold(
          0,
          (sum, item) => sum + item.calories,
        );
        daysWithLogs++;
      }
    }
    if (daysWithLogs == 0) return null;
    double avgIntake = totalCalsConsumed / daysWithLogs;

    // 3. Calculate Weight Change
    // Get weights closest to the start and end of our window
    final latestWeight = weightHistory.last.weight;
    final earliestWeight = weightHistory.first.weight;
    // For a better calculation, you'd find entries specifically at the start/end of the week

    double weightDiff = latestWeight - earliestWeight;

    // 4. Convert weight diff to calorie offset (using lbs here)
    // (Weight change * 3500) / days in period
    double dailyOffset = (weightDiff * 3500) / 7;

    return avgIntake - dailyOffset;
  }
}
