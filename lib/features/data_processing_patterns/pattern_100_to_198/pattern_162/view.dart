import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/state_architecture_example.dart';

class Pattern162View extends StatelessWidget {
  const Pattern162View({super.key});

  @override
  Widget build(BuildContext context) => const StateArchitectureExample(
    title: 'Pattern 162: StateNotifier',
    description: 'StateNotifier パターン実装。',
    bloc: false,
  );
}
