import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/amount_dialog.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.getLogForSelectedDate();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 20,
              runSpacing: 10,
              children: [
                StatCard(
                  label: "Calories",
                  value: state.totalCals.toStringAsFixed(0),
                  target: state.profile.calorieGoal,
                ),
                StatCard(
                  label: "Fat",
                  value: "${state.totalFat.toStringAsFixed(1)}g",
                  target: state.profile.fatGoal,
                ),
                StatCard(
                  label: "Sodium",
                  value: "${state.totalSodium.toStringAsFixed(0)}mg",
                ),
                StatCard(
                  label: "Carbs",
                  value: "${state.totalCarbs.toStringAsFixed(1)}g",
                  target: state.profile.carbGoal,
                ),
                StatCard(
                  label: "Fiber",
                  value: "${state.totalFiber.toStringAsFixed(1)}g",
                ),
                StatCard(
                  label: "Protein",
                  value: "${state.totalProtein.toStringAsFixed(1)}g",
                  target: state.profile.proteinGoal,
                ),
                StatCard(
                  label: "Spent",
                  value: "\$${state.totalSpent.toStringAsFixed(2)}",
                  target: state.profile.budgetGoal,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => state.setDate(
                  state.selectedDate.subtract(const Duration(days: 1)),
                ),
              ),
              Text(
                "${state.selectedDate.month}/${state.selectedDate.day}/${state.selectedDate.year}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => state.setDate(
                  state.selectedDate.add(const Duration(days: 1)),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final item = entries[i];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) async =>
                      await state.deleteDiaryEntry(state.selectedDate, item.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      "${item.servingSize} ${item.servingUnit.name} • ${item.calories.toStringAsFixed(0)} kcal",
                    ),
                    trailing: Text("\$${item.price.toStringAsFixed(2)}"),
                    onTap: () => showAmountDialog(
                      context,
                      item,
                      state.selectedDate,
                      existingItem: item,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
