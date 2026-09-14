import 'package:flutter/material.dart';

import '../features/counter_playground/domain/counter_playground_controller.dart';
import '../features/counter_playground/presentation/counter_playground_page.dart';

/// Thin public wrapper; implementation lives in features/.
///
/// Owns a single [CounterPlaygroundController] for the screen lifetime.
/// Disposal is handled by [CounterPlaygroundPage].
class CounterPlaygroundScreen extends StatefulWidget {
  const CounterPlaygroundScreen({super.key});

  @override
  State<CounterPlaygroundScreen> createState() =>
      _CounterPlaygroundScreenState();
}

class _CounterPlaygroundScreenState extends State<CounterPlaygroundScreen> {
  late final CounterPlaygroundController _controller =
      CounterPlaygroundController();

  @override
  Widget build(BuildContext context) =>
      CounterPlaygroundPage(controller: _controller);
}
