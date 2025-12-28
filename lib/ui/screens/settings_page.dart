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
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: last7
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
              .toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 4,
          belowBarData: BarAreaData(show: true, color: Colors.green),
        ),
      ],
    );
  }
}
