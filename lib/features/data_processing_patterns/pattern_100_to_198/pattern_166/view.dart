import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/counter_architecture_example.dart';

class Pattern166View extends StatelessWidget {
  const Pattern166View({super.key});
  @override Widget build(BuildContext context) => const CounterArchitectureExample(
    title: 'Pattern 166: MVC',
    description: 'MVC パターンの Flutter 実装。',
    architecture: CounterArchitecture.mvc,
  );
}
