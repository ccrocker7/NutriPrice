import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const NutriPriceApp());

class NutriPriceApp extends StatelessWidget {
  const NutriPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPrice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const NutriPriceHomeScreen(),
    );
  }
}