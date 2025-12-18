// lib/pantry.dart

import 'package:flutter/material.dart';

class Pantry extends StatelessWidget {
  const Pantry({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Text('Welcome to your Pantry!'),
    );
  }
}
