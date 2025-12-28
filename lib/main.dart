import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/schema_migration.dart';
import 'data/repositories/pantry_repository.dart';
import 'data/repositories/diary_repository.dart';
import 'data/repositories/weight_repository.dart';
import 'data/repositories/user_profile_repository.dart';
import 'providers/app_state.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run schema migration before initializing app state
  await SchemaMigration.runMigrations();

  // Initialize all repositories
  final pantryRepository = PantryRepository();
  final diaryRepository = DiaryRepository();
  final weightRepository = WeightRepository();
  final profileRepository = UserProfileRepository();

  runApp(
    MultiProvider(
      providers: [
        // Provide repositories (for potential direct access if needed)
        Provider<PantryRepository>(create: (_) => pantryRepository),
        Provider<DiaryRepository>(create: (_) => diaryRepository),
        Provider<WeightRepository>(create: (_) => weightRepository),
        Provider<UserProfileRepository>(create: (_) => profileRepository),

        // Provide AppState with injected repositories
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(
            pantryRepository: pantryRepository,
            diaryRepository: diaryRepository,
            weightRepository: weightRepository,
            profileRepository: profileRepository,
          ),
        ),
      ],
      child: const NutriPriceApp(),
    ),
  );
}

class NutriPriceApp extends StatelessWidget {
  const NutriPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutriprice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
