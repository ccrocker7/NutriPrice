import 'package:flutter/material.dart';
import '../services/database_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calController.text = DatabaseService.getGoal(
      'calories_goal',
      defaultValue: 2000,
    ).round().toString();
    _proteinController.text = DatabaseService.getGoal(
      'protein_goal',
      defaultValue: 150,
    ).toStringAsFixed(1);
    _carbController.text = DatabaseService.getGoal(
      'carbs_goal',
      defaultValue: 200,
    ).toStringAsFixed(1);
    _fatController.text = DatabaseService.getGoal(
      'fat_goal',
      defaultValue: 65,
    ).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _calController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _saveGoal(String key, String value) {
    final double? val = double.tryParse(value);
    if (val != null) {
      DatabaseService.saveGoal(key, val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "Nutrition Goals"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildGoalInput(
                    "Daily Calories",
                    _calController,
                    "kcal",
                    (v) => _saveGoal('calories_goal', v),
                  ),
                  _buildGoalInput(
                    "Daily Protein",
                    _proteinController,
                    "g",
                    (v) => _saveGoal('protein_goal', v),
                  ),
                  _buildGoalInput(
                    "Daily Carbs",
                    _carbController,
                    "g",
                    (v) => _saveGoal('carbs_goal', v),
                  ),
                  _buildGoalInput(
                    "Daily Fat",
                    _fatController,
                    "g",
                    (v) => _saveGoal('fat_goal', v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Statistics"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Estimated TDEE",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<double?>(
                    future: Future.value(
                      DatabaseService.calculateEstimatedTDEE(),
                    ),
                    builder: (context, snapshot) {
                      final tdee = snapshot.data;
                      if (tdee == null) {
                        return const Text(
                          "Log weight measurements over at least 2 days to see your estimated Total Daily Energy Expenditure.",
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${tdee.round()}",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "kcal / day",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Based on your weight change and calorie intake over the last 30 days.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "About"),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("Version"),
              trailing: Text("1.0.0"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInput(
    String label,
    TextEditingController controller,
    String unit,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: unit,
              hintText: "0.0",
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16, // Better touch target
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
