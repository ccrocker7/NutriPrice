import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/weight_entry.dart';

class WeightDialog {
  static void show(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Log Weight"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Weight (lbs)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Date: "),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            DateTime.now().hour,
                            DateTime.now().minute,
                          );
                        });
                      }
                    },
                    child: Text(
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid weight"),
                    ),
                  );
                  return;
                }

                await DatabaseService.saveWeight(
                  WeightEntry(weight: weight, date: selectedDate),
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Weight saved!"),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(
                      bottom: 100,
                      left: 24,
                      right: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueGrey[800],
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
