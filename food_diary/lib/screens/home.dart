// lib/home.dart

import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome Home!', style: TextStyle(fontSize: 24))
    );
  }
}
