import 'package:flutter/material.dart';
import '../data/repositories/pantry_repository.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../data/repositories/user_profile_repository.dart';
import '../domain/models/food_item.dart';
import '../domain/models/food_unit.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/weight_entry.dart';
import '../domain/services/tdee_calculator.dart';
import '../domain/services/unit_converter.dart';

/// Main application state managed via ChangeNotifier
///
/// Uses dependency injection with repositories to keep persistence logic
/// separate from state management
class AppState extends ChangeNotifier {
  // Repositories (injected via constructor)
  final PantryRepository _pantryRepository;
  final DiaryRepository _diaryRepository;
  final WeightRepository _weightRepository;
  final UserProfileRepository _profileRepository;

  // Cached state
  List<FoodItem> _pantry = [];
  Map<DateTime, List<FoodItem>> _diary = {};
  List<WeightEntry> _weightHistory = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  UserProfile _profile = UserProfile();

  AppState({
    required PantryRepository pantryRepository,
    required DiaryRepository diaryRepository,
    required WeightRepository weightRepository,
    required UserProfileRepository profileRepository,
  }) : _pantryRepository = pantryRepository,
       _diaryRepository = diaryRepository,
       _weightRepository = weightRepository,
       _profileRepository = profileRepository {
    _loadFromRepositories();
  }

  // Getters
  List<FoodItem> get pantry => _pantry;
  DateTime get selectedDate => _selectedDate;
  UserProfile get profile => _profile;

  List<WeightEntry> get weightHistory {
    final sorted = List<WeightEntry>.from(_weightHistory);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  // Load data from repositories
  Future<void> _loadFromRepositories() async {
    _profile = await _profileRepository.loadProfile();
    _pantry = await _pantryRepository.loadPantry();
    _weightHistory = await _weightRepository.loadWeightHistory();
    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  // Date selection
  void setDate(DateTime date) {
    _selectedDate = DateUtils.dateOnly(date);
    notifyListeners();
  }

  // Profile operations
  Future<void> updateGoals(
    double cal,
    double fat,
    double carb,
    double protein,
    double budget,
  ) async {
    await _profileRepository.updateGoals(
      currentProfile: _profile,
      calorieGoal: cal,
      fatGoal: fat,
      carbGoal: carb,
      proteinGoal: protein,
      budgetGoal: budget,
    );
    _profile = await _profileRepository.loadProfile();
    notifyListeners();
  }

  // Pantry operations
  Future<void> addToPantry(FoodItem item) async {
    await _pantryRepository.addItem(item);
    _pantry = await _pantryRepository.loadPantry();
    notifyListeners();
  }

  Future<void> updatePantryItem(FoodItem updatedItem) async {
    await _pantryRepository.updateItem(updatedItem);
    _pantry = await _pantryRepository.loadPantry();
    notifyListeners();
  }

  Future<void> deletePantryItem(String id) async {
    await _pantryRepository.deleteItem(id);
    _pantry = await _pantryRepository.loadPantry();
    notifyListeners();
  }

  // Weight operations
  Future<void> logWeight(DateTime date, double weight) async {
    await _weightRepository.logWeight(date, weight);
    _weightHistory = await _weightRepository.loadWeightHistory();
    notifyListeners();
  }

  Future<double?> getWeightForDate(DateTime date) async {
    return await _weightRepository.getWeightForDate(date);
  }

  // Inventory operations
  Future<void> updateInventoryQuantity(
    String pantryItemId,
    double newQuantity,
    FoodUnit unit,
  ) async {
    final pantryItem = _pantry.firstWhere((item) => item.id == pantryItemId);
    final updated = pantryItem.copyWith(
      quantityRemaining: newQuantity,
      inventoryUnit: unit,
    );
    await _pantryRepository.updateItem(updated);
    _pantry = await _pantryRepository.loadPantry();
    notifyListeners();
  }

  // Diary operations
  Future<void> logFoodToDate(DateTime date, FoodItem item) async {
    // Check if this item came from pantry
    final pantryItemIndex = _pantry.indexWhere((p) => p.id == item.id);

    await _diaryRepository.logFoodToDate(date, item);

    // If from pantry, decrement inventory
    if (pantryItemIndex != -1) {
      final pantryItem = _pantry[pantryItemIndex];
      final consumed = UnitConverter.convert(
        amount: item.servingSize,
        from: item.servingUnit,
        to: pantryItem.inventoryUnit,
        servingSize: pantryItem.servingSize,
      );

      final updated = pantryItem.copyWith(
        quantityRemaining: pantryItem.quantityRemaining - consumed,
      );

      await _pantryRepository.updateItem(updated);
      _pantry = await _pantryRepository.loadPantry();
    }

    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  Future<void> deleteDiaryEntry(DateTime date, String id) async {
    // Get the item before deleting to refund inventory
    final entries = _diary[date] ?? [];
    final deletedItem = entries.firstWhere(
      (item) => item.id == id,
      orElse: () => entries.first, // Fallback, shouldn't happen
    );

    await _diaryRepository.deleteDiaryEntry(date, id);

    // Check if this item came from pantry and refund inventory
    final pantryItemIndex = _pantry.indexWhere((p) => p.id == deletedItem.id);
    if (pantryItemIndex != -1) {
      final pantryItem = _pantry[pantryItemIndex];
      final refund = UnitConverter.convert(
        amount: deletedItem.servingSize,
        from: deletedItem.servingUnit,
        to: pantryItem.inventoryUnit,
        servingSize: pantryItem.servingSize,
      );

      final updated = pantryItem.copyWith(
        quantityRemaining: pantryItem.quantityRemaining + refund,
      );

      await _pantryRepository.updateItem(updated);
      _pantry = await _pantryRepository.loadPantry();
    }

    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  Future<void> updateDiaryEntry(
    DateTime date,
    String id,
    FoodItem updatedItem,
  ) async {
    // Get the old item to calculate the difference
    final entries = _diary[date] ?? [];
    final oldItem = entries.firstWhere(
      (item) => item.id == id,
      orElse: () => updatedItem, // Fallback to updated if not found
    );

    await _diaryRepository.updateDiaryEntry(date, id, updatedItem);

    // If from pantry, adjust inventory for the difference
    final pantryItemIndex = _pantry.indexWhere((p) => p.id == updatedItem.id);
    if (pantryItemIndex != -1) {
      final pantryItem = _pantry[pantryItemIndex];

      // Convert old and new amounts to inventory units
      final oldConsumed = UnitConverter.convert(
        amount: oldItem.servingSize,
        from: oldItem.servingUnit,
        to: pantryItem.inventoryUnit,
        servingSize: pantryItem.servingSize,
      );

      final newConsumed = UnitConverter.convert(
        amount: updatedItem.servingSize,
        from: updatedItem.servingUnit,
        to: pantryItem.inventoryUnit,
        servingSize: pantryItem.servingSize,
      );

      // Adjust: refund old, then deduct new
      final netChange = newConsumed - oldConsumed;

      final updated = pantryItem.copyWith(
        quantityRemaining: pantryItem.quantityRemaining - netChange,
      );

      await _pantryRepository.updateItem(updated);
      _pantry = await _pantryRepository.loadPantry();
    }

    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  // Diary queries
  List<FoodItem> getLogForSelectedDate() => _diary[_selectedDate] ?? [];

  double get totalCals =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.calories);
  double get totalFat => getLogForSelectedDate().fold(0, (s, i) => s + i.fat);
  double get totalSodium =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.sodium);
  double get totalCarbs =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.carbs);
  double get totalFiber =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.fiber);
  double get totalProtein =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.protein);
  double get totalSpent =>
      getLogForSelectedDate().fold(0, (s, i) => s + i.price);

  // TDEE calculation (delegates to service)
  double? calculateEstimatedTDEE() {
    return TdeeCalculator.calculate(_weightHistory, _diary);
  }
}
