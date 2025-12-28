import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/weight_entry.dart';

class WeightRepository {
  static const String _weightHistoryKey = 'weightHistory';

  /// Loads weight history from SharedPreferences
  Future<List<WeightEntry>> loadWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final weightStr = prefs.getString(_weightHistoryKey);

    if (weightStr == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(weightStr);
      return jsonList.map((json) => WeightEntry.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  /// Saves weight history to SharedPreferences
  Future<void> saveWeightHistory(List<WeightEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_weightHistoryKey, jsonEncode(jsonList));
  }

  /// Logs weight for a specific date
  /// If an entry already exists for that date, it will be replaced
  Future<void> logWeight(DateTime date, double weight) async {
    final entries = await loadWeightHistory();

    // Remove any existing entry for this date
    entries.removeWhere((w) => DateUtils.isSameDay(w.date, date));

    // Add the new entry
    entries.add(WeightEntry(date: DateUtils.dateOnly(date), weight: weight));

    await saveWeightHistory(entries);
  }

  /// Gets weight for a specific date
  /// Returns null if no entry exists for that date
  Future<double?> getWeightForDate(DateTime date) async {
    final entries = await loadWeightHistory();

    try {
      return entries
          .firstWhere((w) => DateUtils.isSameDay(w.date, date))
          .weight;
    } catch (_) {
      return null;
    }
  }
}
