import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_product.dart';

class SpendingChart extends StatelessWidget {
  final List<FoodProduct> entries;

  const SpendingChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text("No spending data."));
    }

    // 1. Group by date and sum price
    final Map<int, double> dailySpending = {};
    for (var entry in entries) {
      if (entry.dateAdded == null) continue;

      // Normalize to midnight
      final date = DateTime(
        entry.dateAdded!.year,
        entry.dateAdded!.month,
        entry.dateAdded!.day,
      );
      final ms = date.millisecondsSinceEpoch;

      final price = double.tryParse(entry.price ?? '0') ?? 0.0;
      dailySpending[ms] = (dailySpending[ms] ?? 0) + price;
    }

    if (dailySpending.isEmpty) {
      return const Center(child: Text("No spending data with dates."));
    }

    // 2. Convert to spots
    final sortedKeys = dailySpending.keys.toList()..sort();
    final spots = sortedKeys.map((ms) {
      return FlSpot(ms.toDouble(), dailySpending[ms]!);
    }).toList();

    // 3. Calculate bounds and filtering
    // Only show last 30 days logic can be done here or in parent.
    // Parent is doing it for weight, let's do it here for consistency or assume passed list is unfiltered history?
    // Let's rely on parent passing valid data, but here we process what we get.
    // Actually, parent passes ALL diary entries potentially. We should filtered recent ones here similar to weight graph.

    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    final recentSpots = spots.where((s) => s.x >= thirtyDaysAgo).toList();

    // If filtered result is empty
    if (recentSpots.isEmpty && spots.isNotEmpty) {
      // Maybe just show the last few available if none in 30 days?
      // Or just empty state. Let's stick to empty state if nothing in 30 days.
      return const Center(child: Text("No spending in last 30 days."));
    } else if (recentSpots.isEmpty) {
      return const Center(child: Text("No spending data."));
    }

    final minX = recentSpots.first.x;
    final maxX = recentSpots.last.x;

    // Bounds for Y
    final minY = 0.0;
    final maxY =
        recentSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) +
        5; // padding

    // Interval logic
    double xInterval = (maxX - minX) / 5;
    if (xInterval <= 0) xInterval = 86400000;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: true),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d)),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: recentSpots,
                isCurved: true,
                color: Colors.green, // Green for money
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
