import 'package:flutter/material.dart';
import '../data/repositories/pantry_repository.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../data/repositories/user_profile_repository.dart';
import '../domain/models/food_item.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/weight_entry.dart';
import '../domain/services/tdee_calculator.dart';

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

  // Diary operations
  Future<void> logFoodToDate(DateTime date, FoodItem item) async {
    await _diaryRepository.logFoodToDate(date, item);
    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  Future<void> deleteDiaryEntry(DateTime date, String id) async {
    await _diaryRepository.deleteDiaryEntry(date, id);
    _diary = await _diaryRepository.loadDiary();
    notifyListeners();
  }

  Future<void> updateDiaryEntry(
    DateTime date,
    String id,
    FoodItem updatedItem,
  ) async {
    await _diaryRepository.updateDiaryEntry(date, id, updatedItem);
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
