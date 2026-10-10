import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/counter_architecture_example.dart';

class Pattern167View extends StatelessWidget {
  const Pattern167View({super.key});
  @override Widget build(BuildContext context) => const CounterArchitectureExample(
    title: 'Pattern 167: MVVM',
    description: 'MVVM パターンの Flutter 実装。',
    architecture: CounterArchitecture.mvvm,
  );
}
