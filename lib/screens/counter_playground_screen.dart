import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../widgets/nav_button.dart';

class CounterPlaygroundScreen extends StatefulWidget {
  const CounterPlaygroundScreen({super.key});

  @override
  State<CounterPlaygroundScreen> createState() => _CounterPlaygroundScreenState();
}

class _CounterPlaygroundScreenState extends State<CounterPlaygroundScreen> {
  var _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Playground 👾'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Text(_counter >= 10 ? 'Too much 😈' : '', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              FloatingActionButton(onPressed: _incrementCounter, child: const Icon(Icons.add)),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: const [
                  NavButton(label: 'Home 🏠', routeName: AppRoutes.home),
                  NavButton(label: 'Irony Generator 🥐', routeName: AppRoutes.ironyGenerator),
                  NavButton(label: 'Composition Generator 🎸', routeName: AppRoutes.compositionGenerator),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
