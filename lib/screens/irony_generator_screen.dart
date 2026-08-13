import 'dart:math';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../data/ironies.dart';
import '../widgets/nav_button.dart';

class IronyGeneratorScreen extends StatefulWidget {
  const IronyGeneratorScreen({super.key});

  @override
  State<IronyGeneratorScreen> createState() => _IronyGeneratorScreenState();
}

class _IronyGeneratorScreenState extends State<IronyGeneratorScreen> {
  final String irony = Ironies.ironicList[Random().nextInt(Ironies.ironicList.length)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irony Generator 🥐'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(irony, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: const [
                  NavButton(label: 'Home 🏠', routeName: AppRoutes.home),
                  NavButton(label: 'Counter Playground 👾', routeName: AppRoutes.counterPlayground),
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
