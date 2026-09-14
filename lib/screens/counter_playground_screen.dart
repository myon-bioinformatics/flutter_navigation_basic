import 'package:flutter/material.dart';

import '../features/counter_playground/domain/counter_playground_controller.dart';
import '../features/counter_playground/presentation/counter_playground_page.dart';

/// Thin public wrapper; implementation lives in features/.
class CounterPlaygroundScreen extends StatelessWidget {
  const CounterPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) => CounterPlaygroundPage(
        controller: CounterPlaygroundController(),
      );
}
