import 'package:flutter/material.dart';

import '../features/composition_generator/domain/composition_generator_controller.dart';
import '../features/composition_generator/presentation/composition_generator_page.dart';

/// Thin public wrapper; implementation lives in features/.
///
/// Creates one [CompositionGeneratorController] for the screen lifetime and
/// hands it to [CompositionGeneratorPage]. The controller is a plain object
/// (no dispose); the wrapper keeps the single instance stable across rebuilds.
class CompositionStudioScreen extends StatefulWidget {
  const CompositionStudioScreen({super.key});

  @override
  State<CompositionStudioScreen> createState() =>
      _CompositionStudioScreenState();
}

class _CompositionStudioScreenState extends State<CompositionStudioScreen> {
  late final CompositionGeneratorController _controller =
      CompositionGeneratorController();

  @override
  Widget build(BuildContext context) =>
      CompositionGeneratorPage(controller: _controller);
}
