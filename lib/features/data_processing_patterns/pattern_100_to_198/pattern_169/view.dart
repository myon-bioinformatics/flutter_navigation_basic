import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/counter_architecture_example.dart';

class Pattern169View extends StatelessWidget {
  const Pattern169View({super.key});
  @override Widget build(BuildContext context) => const CounterArchitectureExample(
    title: 'Pattern 169: CleanArch',
    description: 'Clean Architecture の実装例。',
    architecture: CounterArchitecture.clean,
  );
}
