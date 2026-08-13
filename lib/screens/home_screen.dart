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
        title: const Text('Home 🏠'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(today, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: const <Widget>[
                  NavButton(
                    label: 'Counter Playground 👾',
                    routeName: AppRoutes.counterPlayground,
                  ),
                  NavButton(
                    label: 'Irony Generator 🥐',
                    routeName: AppRoutes.ironyGenerator,
                  ),
                  NavButton(
                    label: 'Composition Generator 🎸',
                    routeName: AppRoutes.compositionGenerator,
                  ),
                  NavButton(
                    label: 'Navigation Hub 🗺️ (198 Screens)',
                    routeName: AppRoutes.hub,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
