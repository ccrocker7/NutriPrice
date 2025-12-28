import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

/// Shows a dialog to log weight for a given date
Future<void> showWeightDialog(BuildContext context, DateTime date) async {
  final state = context.read<AppState>();
  final existingWeight = await state.getWeightForDate(date);

  if (!context.mounted) return;

  final ctrl = TextEditingController(text: existingWeight?.toString() ?? "");

  return showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text("Log Weight"),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: "Weight"),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final weight = double.tryParse(ctrl.text) ?? 0;
            if (weight > 0) {
              await state.logWeight(date, weight);
            }
            if (context.mounted) {
              Navigator.pop(c);
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
