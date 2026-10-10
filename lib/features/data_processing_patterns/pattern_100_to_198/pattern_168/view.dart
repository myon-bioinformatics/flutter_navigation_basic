import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/counter_architecture_example.dart';

class Pattern168View extends StatelessWidget {
  const Pattern168View({super.key});
  @override Widget build(BuildContext context) => const CounterArchitectureExample(
    title: 'Pattern 168: MVP',
    description: 'MVP パターンの Flutter 実装。',
    architecture: CounterArchitecture.mvp,
  );
}
