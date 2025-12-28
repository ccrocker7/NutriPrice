import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_state.dart';
import '../../domain/models/weight_entry.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _cal, _fat, _carb, _prot, _bud;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _cal = TextEditingController(text: p.calorieGoal.toString());
    _fat = TextEditingController(text: p.fatGoal.toString());
    _carb = TextEditingController(text: p.carbGoal.toString());
    _prot = TextEditingController(text: p.proteinGoal.toString());
    _bud = TextEditingController(text: p.budgetGoal.toString());
  }

  @override
  void dispose() {
    _cal.dispose();
    _fat.dispose();
    _carb.dispose();
    _prot.dispose();
    _bud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weight Progress",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: state.weightHistory.isEmpty
                  ? const Center(child: Text("No weight logs yet."))
                  : LineChart(_chartData(state.weightHistory)),
            ),
            const Divider(height: 40),
            const Text(
              "Estimated TDEE",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final tdee = state.calculateEstimatedTDEE();
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          tdee != null
                              ? "${tdee.toStringAsFixed(0)} kcal"
                              : "Need more data...",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Based on your last 7 days of logs and weight changes.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        if (tdee != null)
                          TextButton(
                            onPressed: () => state.updateGoals(
                              tdee,
                              state.profile.fatGoal,
                              state.profile.carbGoal,
                              state.profile.proteinGoal,
                              state.profile.budgetGoal,
                            ),
                            child: const Text("Set as Daily Goal"),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 40),
            const Text(
              "Daily Goals",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            _field(
              "Calories",
              _cal,
              (v) => state.updateGoals(
                v,
                state.profile.fatGoal,
                state.profile.carbGoal,
                state.profile.proteinGoal,
                state.profile.budgetGoal,
              ),
            ),
            _field(
              "Fat (g)",
              _fat,
              (v) => state.updateGoals(
                state.profile.calorieGoal,
                v,
                state.profile.carbGoal,
                state.profile.proteinGoal,
                state.profile.budgetGoal,
              ),
            ),
            _field(
              "Carbs (g)",
              _carb,
              (v) => state.updateGoals(
                state.profile.calorieGoal,
                state.profile.fatGoal,
                v,
                state.profile.proteinGoal,
                state.profile.budgetGoal,
              ),
            ),
            _field(
              "Protein (g)",
              _prot,
              (v) => state.updateGoals(
                state.profile.calorieGoal,
                state.profile.fatGoal,
                state.profile.carbGoal,
                v,
                state.profile.budgetGoal,
              ),
            ),
            _field(
              "Budget (\$)",
              _bud,
              (v) => state.updateGoals(
                state.profile.calorieGoal,
                state.profile.fatGoal,
                state.profile.carbGoal,
                state.profile.proteinGoal,
                v,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    Function(double) update,
  ) => TextField(
    controller: ctrl,
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (v) => update(double.tryParse(v) ?? 0),
  );

  LineChartData _chartData(List<WeightEntry> history) {
    final last7 = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    // Find min and max weights for Y-axis scaling
    final weights = last7.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange > 0 ? weightRange * 0.1 : 5.0;

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: last7.length > 1 ? (last7.length - 1) / 3 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= last7.length) return const Text('');

              // Only show labels at the beginning, middle, and end to avoid crowding
              final shouldShow =
                  index == 0 ||
                  index == (last7.length / 2).floor() ||
                  index == last7.length - 1;

              if (!shouldShow) return const Text('');

              final date = last7[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minY: minWeight - padding,
      maxY: maxWeight + padding,
      lineBarsData: [
        LineChartBarData(
          spots: last7
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
              .toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withAlpha(51), // 20% opacity = 51/255
          ),
        ),
      ],
    );
  }
}
