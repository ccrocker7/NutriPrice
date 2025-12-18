import 'package:flutter/material.dart';
import 'home.dart';
import 'pantry.dart';
import 'add_food.dart';
import 'history.dart';
import 'settings.dart';

void main() => runApp(NutriPriceApp());

class NutriPriceApp extends StatelessWidget {
  const NutriPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPrice',
      theme: ThemeData.dark(),
      home: NutriPriceExample()     
      );
  }
}

class NutriPriceExample extends StatelessWidget {
  const NutriPriceExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('NutriPrice'),
          centerTitle: true,
        ),
        body: TabBarView(
          children: <Widget>[
            Center(child: Home()),
            Center(child: Pantry()),
            Center(child: FormExample()),
            Center(child: History()),
            Center(child: Settings()),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          // color: Theme.of(context).colorScheme.inversePrimary,
          child: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.dashboard)),
              Tab(icon: Icon(Icons.add)),
              Tab(icon: Icon(Icons.show_chart)),
              Tab(icon: Icon(Icons.settings)),
            ],
          ),
        ),
      ),
    );
  }
}