import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/counter_architecture_example.dart';

class Pattern170View extends StatelessWidget {
  const Pattern170View({super.key});
  @override Widget build(BuildContext context) => const CounterArchitectureExample(
    title: 'Pattern 170: AtomState',
    description: 'Atom 状態管理パターン (Riverpod 風擬似実装)。',
    architecture: CounterArchitecture.atom,
  );
}
