import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/state_architecture_example.dart';

class Pattern163View extends StatelessWidget {
  const Pattern163View({super.key});

  @override
  Widget build(BuildContext context) => const StateArchitectureExample(
    title: 'Pattern 163: Bloc',
    description: 'BLoC パターンの擬似実装。',
    bloc: true,
  );
}
