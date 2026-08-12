import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/routes.dart';
import '../widgets/nav_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime get nowadays => DateTime.now();
  String get today => DateFormat('yyyy/MM/dd(E)').format(nowadays);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen1: HomeApp🏠'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                today,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 2👾', routeName: AppRoutes.screen2),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 3🥐', routeName: AppRoutes.screen3),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Go to Screen 4🎸', routeName: AppRoutes.screen4),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              NavButton(label: 'Navigation Hub 🗺️ (198 Screens)', routeName: AppRoutes.hub),
            ],
          ),
        ],
      ),
    );
  }
}
