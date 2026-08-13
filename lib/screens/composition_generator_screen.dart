import 'dart:math';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../data/composer.dart';
import '../widgets/nav_button.dart';

class CompositionGeneratorScreen extends StatefulWidget {
  const CompositionGeneratorScreen({super.key});

  @override
  State<CompositionGeneratorScreen> createState() => _CompositionGeneratorScreenState();
}

class _CompositionGeneratorScreenState extends State<CompositionGeneratorScreen> {
  final String tonicKey = Composer.diatonicScaleList[
      Random().nextInt(Composer.diatonicScaleList.length)];
  final int bpm = 100 + Random().nextInt(61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composition Generator 🎸'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Key: $tonicKey, BPM: $bpm',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: const [
                  NavButton(label: 'Home 🏠', routeName: AppRoutes.home),
                  NavButton(label: 'Counter Playground 👾', routeName: AppRoutes.counterPlayground),
                  NavButton(label: 'Irony Generator 🥐', routeName: AppRoutes.ironyGenerator),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
