import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_food_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MacroEconomicsApp(),
    ),
  );
}

class MacroEconomicsApp extends StatelessWidget {
  const MacroEconomicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MacroEconomics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODELS ---
enum FoodUnit { grams, ounces, servings }

class UserProfile {
  final String name;
  final double calorieGoal, fatGoal, carbGoal, proteinGoal, budgetGoal;

  UserProfile({
    this.name = "User",
    this.calorieGoal = 1600,
    this.fatGoal = 50,
    this.carbGoal = 150,
    this.proteinGoal = 100,
    this.budgetGoal = 15.00,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'calorieGoal': calorieGoal, 'fatGoal': fatGoal,
    'carbGoal': carbGoal, 'proteinGoal': proteinGoal, 'budgetGoal': budgetGoal,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? "User",
    calorieGoal: (json['calorieGoal'] ?? 1600).toDouble(),
    fatGoal: (json['fatGoal'] ?? 50).toDouble(),
    carbGoal: (json['carbGoal'] ?? 150).toDouble(),
    proteinGoal: (json['proteinGoal'] ?? 100).toDouble(),
    budgetGoal: (json['budgetGoal'] ?? 15.00).toDouble(),
  );

  UserProfile copyWith({double? calorieGoal, double? fatGoal, double? carbGoal, double? proteinGoal, double? budgetGoal}) {
    return UserProfile(
      name: name,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      budgetGoal: budgetGoal ?? this.budgetGoal,
    );
  }
}

class FoodItem {
  final String id, name;
  final double calories, fat, sodium, carbs, fiber, protein, price, servingSize;
  final FoodUnit servingUnit;

  FoodItem({required this.id, required this.name, required this.calories, required this.fat, required this.sodium, required this.carbs, required this.fiber, required this.protein, required this.price, required this.servingSize, required this.servingUnit});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'calories': calories, 'fat': fat, 'sodium': sodium,
    'carbs': carbs, 'fiber': fiber, 'protein': protein, 'price': price,
    'servingSize': servingSize, 'servingUnit': servingUnit.index,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'], name: json['name'], 
    calories: json['calories'].toDouble(), fat: json['fat'].toDouble(),
    sodium: json['sodium'].toDouble(), carbs: json['carbs'].toDouble(),
    fiber: json['fiber'].toDouble(), protein: json['protein'].toDouble(),
    price: json['price'].toDouble(), servingSize: json['servingSize'].toDouble(),
    servingUnit: FoodUnit.values[json['servingUnit']],
  );
}

class WeightEntry {
  final DateTime date;
  final double weight;
  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'weight': weight};
  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    date: DateTime.parse(json['date']), weight: json['weight'].toDouble(),
  );
}

// --- STATE MANAGEMENT ---
class AppState extends ChangeNotifier {
  final List<FoodItem> _pantry = [];
  final Map<DateTime, List<FoodItem>> _diary = {};
  final List<WeightEntry> _weightHistory = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  UserProfile _profile = UserProfile();

  AppState() {
    _loadFromDisk();
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

  // Persistence Methods
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', jsonEncode(_profile.toJson()));
    await prefs.setString('pantry', jsonEncode(_pantry.map((e) => e.toJson()).toList()));
    await prefs.setString('weightHistory', jsonEncode(_weightHistory.map((e) => e.toJson()).toList()));
    
    // Convert DateTime keys to Strings for JSON map compatibility
    final diaryMap = _diary.map((key, value) => MapEntry(key.toIso8601String(), value.map((e) => e.toJson()).toList()));
    await prefs.setString('diary', jsonEncode(diaryMap));
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    
    final profileStr = prefs.getString('userProfile');
    if (profileStr != null) _profile = UserProfile.fromJson(jsonDecode(profileStr));

    final pantryStr = prefs.getString('pantry');
    if (pantryStr != null) {
      _pantry.clear();
      _pantry.addAll((jsonDecode(pantryStr) as List).map((e) => FoodItem.fromJson(e)));
    }

    final weightStr = prefs.getString('weightHistory');
    if (weightStr != null) {
      _weightHistory.clear();
      _weightHistory.addAll((jsonDecode(weightStr) as List).map((e) => WeightEntry.fromJson(e)));
    }

    final diaryStr = prefs.getString('diary');
    if (diaryStr != null) {
      _diary.clear();
      final Map<String, dynamic> decodedDiary = jsonDecode(diaryStr);
      decodedDiary.forEach((key, value) {
        _diary[DateTime.parse(key)] = (value as List).map((e) => FoodItem.fromJson(e)).toList();
      });
    }
    notifyListeners();
  }

  // Logic Actions
  void setDate(DateTime date) {
    _selectedDate = DateUtils.dateOnly(date);
    notifyListeners();
  }

  void updateGoals(double cal, double fat, double carb, double protein, double budget) {
    _profile = _profile.copyWith(calorieGoal: cal, fatGoal: fat, carbGoal: carb, proteinGoal: protein, budgetGoal: budget);
    _saveToDisk();
    notifyListeners();
  }

  void addToPantry(FoodItem item) { _pantry.add(item); _saveToDisk(); notifyListeners(); }
  void updatePantryItem(FoodItem updatedItem) {
    final index = _pantry.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _pantry[index] = updatedItem;
      _saveToDisk(); // Crucial for persistence
      notifyListeners();
    }
  }
  void deletePantryItem(String id) { _pantry.removeWhere((item) => item.id == id); _saveToDisk(); notifyListeners(); }
  
  void logWeight(DateTime date, double weight) {
    _weightHistory.removeWhere((w) => DateUtils.isSameDay(w.date, date));
    _weightHistory.add(WeightEntry(date: DateUtils.dateOnly(date), weight: weight));
    _saveToDisk();
    notifyListeners();
  }

  void logFoodToDate(DateTime date, FoodItem item) {
    final dateKey = DateUtils.dateOnly(date);
    _diary.putIfAbsent(dateKey, () => []).add(item);
    _saveToDisk();
    notifyListeners();
  }

  void deleteDiaryEntry(DateTime date, String id) {
    final dateKey = DateUtils.dateOnly(date);
    _diary[dateKey]?.removeWhere((item) => item.id == id);
    _saveToDisk();
    notifyListeners();
  }

  void updateDiaryEntry(DateTime date, String id, double newAmount, FoodUnit newUnit, FoodItem basePantryItem) {
    final dateKey = DateUtils.dateOnly(date);
    final list = _diary[dateKey];
    if (list != null) {
      final index = list.indexWhere((item) => item.id == id);
      if (index != -1) {
        double mult = (newUnit == FoodUnit.servings) ? newAmount : (newAmount / basePantryItem.servingSize);
        list[index] = FoodItem(
          id: id, name: basePantryItem.name, servingUnit: newUnit, servingSize: newAmount,
          calories: basePantryItem.calories * mult, protein: basePantryItem.protein * mult,
          fat: basePantryItem.fat * mult, carbs: basePantryItem.carbs * mult,
          sodium: basePantryItem.sodium * mult, fiber: basePantryItem.fiber * mult,
          price: basePantryItem.price * mult,
        );
        _saveToDisk();
        notifyListeners();
      }
    }
  }

  List<FoodItem> getLogForSelectedDate() => _diary[_selectedDate] ?? [];
  double get totalCals => getLogForSelectedDate().fold(0, (s, i) => s + i.calories);
  double get totalFat => getLogForSelectedDate().fold(0, (s, i) => s + i.fat);
  double get totalSodium => getLogForSelectedDate().fold(0, (s, i) => s + i.sodium);
  double get totalCarbs => getLogForSelectedDate().fold(0, (s, i) => s + i.carbs);
  double get totalFiber => getLogForSelectedDate().fold(0, (s, i) => s + i.fiber);
  double get totalProtein => getLogForSelectedDate().fold(0, (s, i) => s + i.protein);
  double get totalSpent => getLogForSelectedDate().fold(0, (s, i) => s + i.price);
  
  double? getWeightForDate(DateTime date) {
    try { return _weightHistory.firstWhere((w) => DateUtils.isSameDay(w.date, date)).weight; } catch (_) { return null; }
  }
    double? calculateEstimatedTDEE() {
    if (_weightHistory.length < 2 || _diary.isEmpty) return null;

    // 1. Get the date range (last 7 days)
    final end = DateUtils.dateOnly(DateTime.now());
    final start = end.subtract(const Duration(days: 7));

    // 2. Calculate average intake over these days
    double totalCalsConsumed = 0;
    int daysWithLogs = 0;
    for (int i = 0; i <= 7; i++) {
      final date = start.add(Duration(days: i));
      final dayLogs = _diary[date];
      if (dayLogs != null && dayLogs.isNotEmpty) {
        totalCalsConsumed += dayLogs.fold(0, (sum, item) => sum + item.calories);
        daysWithLogs++;
      }
    }
    if (daysWithLogs == 0) return null;
    double avgIntake = totalCalsConsumed / daysWithLogs;

    // 3. Calculate Weight Change
    // Get weights closest to the start and end of our window
    final latestWeight = _weightHistory.last.weight;
    final earliestWeight = _weightHistory.first.weight; 
    // For a better calculation, you'd find entries specifically at the start/end of the week
    
    double weightDiff = latestWeight - earliestWeight;
    
    // 4. Convert weight diff to calorie offset (using lbs here)
    // (Weight change * 3500) / days in period
    double dailyOffset = (weightDiff * 3500) / 7;

    return avgIntake - dailyOffset; 
  }
}

// --- GLOBAL HELPERS ---
void showAmountDialog(BuildContext context, FoodItem baseItem, DateTime date, {FoodItem? existingItem}) {
  final controller = TextEditingController(
    text: existingItem?.servingSize.toString() ?? (baseItem.servingUnit == FoodUnit.servings ? "1" : baseItem.servingSize.toString())
  );
  FoodUnit selectedUnit = existingItem?.servingUnit ?? baseItem.servingUnit;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existingItem == null ? "Add ${baseItem.name}" : "Edit ${baseItem.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.numberWithOptions(decimal: true), autofocus: true),
            const SizedBox(height: 10),
            DropdownButton<FoodUnit>(
              value: selectedUnit,
              isExpanded: true,
              items: FoodUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
              onChanged: (v) => setDialogState(() => selectedUnit = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(controller.text) ?? 0;
              if (amt > 0) {
                double mult = (selectedUnit == FoodUnit.servings) ? amt : (amt / baseItem.servingSize);
                final state = context.read<AppState>();
                if (existingItem == null) {
                  state.logFoodToDate(date, FoodItem(
                    id: const Uuid().v4(), name: baseItem.name, servingSize: amt, servingUnit: selectedUnit,
                    calories: baseItem.calories * mult, protein: baseItem.protein * mult,
                    fat: baseItem.fat * mult, carbs: baseItem.carbs * mult,
                    sodium: baseItem.sodium * mult, fiber: baseItem.fiber * mult,
                    price: baseItem.price * mult,
                  ));
                } else {
                  final pantryItem = state.pantry.firstWhere((p) => p.name == existingItem.name, orElse: () => baseItem);
                  state.updateDiaryEntry(date, existingItem.id, amt, selectedUnit, pantryItem);
                }
                Navigator.pop(context);
              }
            },
            child: Text(existingItem == null ? "Log Entry" : "Update"),
          ),
        ],
      ),
    ),
  );
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const DiaryPage(), const PantryPage(), const SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Pantry'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 ? null : SpeedDial(
        icon: Icons.add,
        backgroundColor: Colors.green,
        children: _selectedIndex == 0 
          ? [
              SpeedDialChild(child: const Icon(Icons.monitor_weight), label: 'Log Weight', onTap: () => _showWeightDialog(context, state)),
              SpeedDialChild(child: const Icon(Icons.inventory_2), label: 'From Pantry', onTap: () => _showPantryPicker(context, state)),
              SpeedDialChild(child: const Icon(Icons.edit_note), label: 'Quick Log', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddFoodScreen(isLoggingOnly: true)))),
            ]
          : [
              SpeedDialChild(child: const Icon(Icons.qr_code_scanner), label: 'Scan Barcode', onTap: () => _scanBarcode(context)),
              SpeedDialChild(child: const Icon(Icons.add_box), label: 'Manual Add', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddFoodScreen()))),
            ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: state.getWeightForDate(state.selectedDate)?.toString() ?? "");
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Log Weight"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Weight"), keyboardType: TextInputType.numberWithOptions(decimal: true), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")), ElevatedButton(onPressed: () { state.logWeight(state.selectedDate, double.tryParse(ctrl.text) ?? 0); Navigator.pop(c); }, child: const Text("Save"))],
    ));
  }

  void _showPantryPicker(BuildContext context, AppState state) {
    showModalBottomSheet(context: context, builder: (c) => ListView.builder(
      itemCount: state.pantry.length,
      itemBuilder: (c, i) => ListTile(title: Text(state.pantry[i].name), onTap: () { Navigator.pop(c); showAmountDialog(context, state.pantry[i], state.selectedDate); }),
    ));
  }

  void _scanBarcode(BuildContext context) async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (c) => const BarcodeScannerPage()));
    if (code != null && context.mounted) _handleBarcode(context, code);
  }

  Future<void> _handleBarcode(BuildContext context, String code) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));
    final r = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$code.json'));
    if (context.mounted) Navigator.pop(context);
    final data = json.decode(r.body);
    if (data['status'] == 1) {
      final p = data['product']; final n = p['nutriments'] ?? {};
      final item = FoodItem(
        id: const Uuid().v4(), name: p['product_name'] ?? "Unknown",
        calories: (n['energy-kcal_serving'] ?? 0).toDouble(),
        fat: (n['fat_serving'] ?? 0).toDouble(), 
        sodium: (n['sodium_serving'] ?? 0).toDouble() * 1000,
        carbs: (n['carbohydrates_serving'] ?? 0).toDouble(), 
        fiber: (n['fiber_serving'] ?? 0).toDouble(),
        protein: (n['proteins_serving'] ?? 0).toDouble(), 
        price: 0.0,
        servingSize: (p['serving_quantity'] ?? 0).toDouble(),
        servingUnit: (p['serving_quantity_unit'] == 'oz') ? FoodUnit.ounces : FoodUnit.grams,
      );
      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (c) => AddFoodScreen(existingItem: item)));
    }
  }
}

// --- SCANNER PAGE ---
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isDetected = false;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          final codes = capture.barcodes;
          if (codes.isNotEmpty && !isDetected) {
            isDetected = true;
            await controller.stop();
            if (context.mounted) Navigator.pop(context, codes.first.rawValue);
          }
        },
      ),
    );
  }
}

// --- DIARY PAGE ---
class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.getLogForSelectedDate();
    return Scaffold(
      // appBar: AppBar(title: const Text("Macro Diary"), centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 20, runSpacing: 10,
              children: [
                _stat("Calories", state.totalCals.toStringAsFixed(0), target: state.profile.calorieGoal),
                _stat("Fat", "${state.totalFat.toStringAsFixed(1)}g", target: state.profile.fatGoal),
                _stat("Sodium", "${state.totalSodium.toStringAsFixed(0)}mg"),
                _stat("Carbs", "${state.totalCarbs.toStringAsFixed(1)}g", target: state.profile.carbGoal),
                _stat("Fiber", "${state.totalFiber.toStringAsFixed(1)}g"),
                _stat("Protein", "${state.totalProtein.toStringAsFixed(1)}g", target: state.profile.proteinGoal),
                _stat("Spent", "\$${state.totalSpent.toStringAsFixed(2)}", target: state.profile.budgetGoal),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => state.setDate(state.selectedDate.subtract(const Duration(days: 1)))),
              Text("${state.selectedDate.month}/${state.selectedDate.day}/${state.selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => state.setDate(state.selectedDate.add(const Duration(days: 1)))),
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
                  onDismissed: (_) => state.deleteDiaryEntry(state.selectedDate, item.id),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text("${item.servingSize} ${item.servingUnit.name} • ${item.calories.toStringAsFixed(0)} kcal"),
                    trailing: Text("\$${item.price.toStringAsFixed(2)}"),
                    onTap: () => showAmountDialog(context, item, state.selectedDate, existingItem: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String val, {double? target}) {
    double current = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    bool isOver = target != null && current > target;
    return Column(children: [Text(label, style: const TextStyle(fontSize: 10)), Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: isOver ? Colors.red : Colors.black))]);
  }
}

// --- PANTRY PAGE ---
class PantryPage extends StatefulWidget {
  const PantryPage({super.key});
  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  String _query = "";
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.pantry.where((i) => i.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      // appBar: AppBar(title: const Text("Pantry Library")),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: TextField(decoration: const InputDecoration(hintText: "Search Pantry...", prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _query = v))),
          Expanded(
            child: ListView.builder(
              itemCount: items.length, 
              itemBuilder: (c, i) {
                final item = items[i];
                return Dismissible(
                  key: Key(item.id),
                  onDismissed: (_) => state.deletePantryItem(item.id),
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  child: ListTile(
                    title: Text(item.name), 
                    subtitle: Text("${item.servingSize} ${item.servingUnit.name}"), 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AddFoodScreen(existingItem: item)))
                  ),
                );
              }
            )
          ),
        ],
      ),
    );
  }
}

// --- SETTINGS PAGE ---
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
  void dispose() { _cal.dispose(); _fat.dispose(); _carb.dispose(); _prot.dispose(); _bud.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      // appBar: AppBar(title: const Text("Settings & Trends")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weight Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: state.weightHistory.isEmpty ? const Center(child: Text("No weight logs yet.")) : LineChart(_chartData(state.weightHistory)),
            ),
            // Inside SettingsPage build method...
            const Divider(height: 40),
            const Text("Estimated TDEE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final tdee = state.calculateEstimatedTDEE();
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          tdee != null ? "${tdee.toStringAsFixed(0)} kcal" : "Need more data...",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Based on your last 7 days of logs and weight changes.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        if (tdee != null)
                          TextButton(
                            onPressed: () => state.updateGoals(tdee, state.profile.fatGoal, state.profile.carbGoal, state.profile.proteinGoal, state.profile.budgetGoal),
                            child: const Text("Set as Daily Goal"),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 40),
            const Text("Daily Goals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            _field("Calories", _cal, (v) => state.updateGoals(v, state.profile.fatGoal, state.profile.carbGoal, state.profile.proteinGoal, state.profile.budgetGoal)),
            _field("Fat (g)", _fat, (v) => state.updateGoals(state.profile.calorieGoal, v, state.profile.carbGoal, state.profile.proteinGoal, state.profile.budgetGoal)),
            _field("Carbs (g)", _carb, (v) => state.updateGoals(state.profile.calorieGoal, state.profile.fatGoal, v, state.profile.proteinGoal, state.profile.budgetGoal)),
            _field("Protein (g)", _prot, (v) => state.updateGoals(state.profile.calorieGoal, state.profile.fatGoal, state.profile.carbGoal, v, state.profile.budgetGoal)),
            _field("Budget (\$)", _bud, (v) => state.updateGoals(state.profile.calorieGoal, state.profile.fatGoal, state.profile.carbGoal, state.profile.proteinGoal, v)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, Function(double) update) => TextField(
    controller: ctrl, decoration: InputDecoration(labelText: label), keyboardType: TextInputType.numberWithOptions(decimal: true), 
    onChanged: (v) => update(double.tryParse(v) ?? 0),
  );

  LineChartData _chartData(List<WeightEntry> history) {
    final last7 = history.length > 7 ? history.sublist(history.length - 7) : history;
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      lineBarsData: [LineChartBarData(
        spots: last7.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList(),
        isCurved: true, color: Colors.green, barWidth: 4, belowBarData: BarAreaData(show: true, color: Colors.green),
      )],
    );
  }
}