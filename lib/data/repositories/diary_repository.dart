import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/food_item.dart';

class DiaryRepository {
  static const String _diaryKey = 'diary';

  /// Loads diary entries from SharedPreferences
  Future<Map<DateTime, List<FoodItem>>> loadDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryStr = prefs.getString(_diaryKey);

    if (diaryStr == null) {
      return {};
    }

    try {
      final Map<String, dynamic> decodedDiary = jsonDecode(diaryStr);
      final Map<DateTime, List<FoodItem>> diary = {};

      decodedDiary.forEach((key, value) {
        final date = DateTime.parse(key);
        final items = (value as List)
            .map((json) => FoodItem.fromJson(json))
            .toList();
        diary[date] = items;
      });

      return diary;
    } catch (e) {
      // If there's an error parsing, return empty map
      return {};
    }
  }

  /// Saves diary entries to SharedPreferences
  Future<void> saveDiary(Map<DateTime, List<FoodItem>> diary) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert DateTime keys to Strings for JSON map compatibility
    final diaryMap = diary.map(
      (key, value) => MapEntry(
        key.toIso8601String(),
        value.map((item) => item.toJson()).toList(),
      ),
    );

    await prefs.setString(_diaryKey, jsonEncode(diaryMap));
  }

  /// Logs a food item to a specific date
  Future<void> logFoodToDate(DateTime date, FoodItem item) async {
    final diary = await loadDiary();
    final dateKey = DateUtils.dateOnly(date);

    diary.putIfAbsent(dateKey, () => []).add(item);

    await saveDiary(diary);
  }

  /// Deletes a diary entry for a specific date and item ID
  Future<void> deleteDiaryEntry(DateTime date, String id) async {
    final diary = await loadDiary();
    final dateKey = DateUtils.dateOnly(date);

    diary[dateKey]?.removeWhere((item) => item.id == id);

    await saveDiary(diary);
  }

  /// Updates a diary entry with new serving information
  Future<void> updateDiaryEntry(
    DateTime date,
    String id,
    FoodItem updatedItem,
  ) async {
    final diary = await loadDiary();
    final dateKey = DateUtils.dateOnly(date);
    final list = diary[dateKey];

    if (list != null) {
      final index = list.indexWhere((item) => item.id == id);
      if (index != -1) {
        list[index] = updatedItem;
        await saveDiary(diary);
      }
    }
  }

  /// Gets the log for a specific date
  Future<List<FoodItem>> getLogForDate(DateTime date) async {
    final diary = await loadDiary();
    final dateKey = DateUtils.dateOnly(date);
    return diary[dateKey] ?? [];
  }
}
