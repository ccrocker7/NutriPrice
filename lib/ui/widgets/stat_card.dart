import 'package:flutter/material.dart';

/// Reusable stat card widget for displaying nutrition/budget metrics
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final double? target;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    double current =
        double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    bool isOver = target != null && current > target!;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOver ? Colors.green : Colors.white,
          ),
        ),
      ],
    );
  }
}
