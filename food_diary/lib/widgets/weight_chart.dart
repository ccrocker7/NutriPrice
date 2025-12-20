import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const WeightChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text("No weight data."));
    }

    // Sort entries by date just to be safe
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final minY =
        sortedEntries
            .map((e) => e.weight)
            .reduce((a, b) => a < b ? a : b)
            .floorToDouble() -
        5;
    final maxY =
        sortedEntries
            .map((e) => e.weight)
            .reduce((a, b) => a > b ? a : b)
            .ceilToDouble() +
        5;

    // Calculate min/max X (date in ms)
    double minX = sortedEntries.first.date.millisecondsSinceEpoch.toDouble();
    double maxX = sortedEntries.last.date.millisecondsSinceEpoch.toDouble();

    // If only one data point or points are very close, range might be 0.
    // Add a buffer of 1 day (86400000 ms) if needed.
    if (maxX <= minX) {
      minX -= 43200000; // -12 hours
      maxX += 43200000; // +12 hours
    }

    // Determine a reasonable interval for X axis titles (e.g., target 5 labels)
    // Avoid interval=0
    double xInterval = (maxX - minX) / 5;
    if (xInterval <= 0) xInterval = 86400000; // Default 1 day

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
                    // Logic to show fewer dates to avoid overlapping
                    // value here is index or milliseconds depending on how we map spots.
                    // Let's map X to index in list for simplicity, but that distorts time gaps.
                    // Better: X is millisecondsSinceEpoch.
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
                      value.toInt().toString(),
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 12),
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
                spots: sortedEntries
                    .map(
                      (e) => FlSpot(
                        e.date.millisecondsSinceEpoch.toDouble(),
                        e.weight,
                      ),
                    )
                    .toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
