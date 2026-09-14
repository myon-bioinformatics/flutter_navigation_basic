import 'package:flutter/material.dart';

import '../features/composition_generator/domain/composition_generator_controller.dart';
import '../features/composition_generator/presentation/composition_generator_page.dart';

/// Thin public wrapper; implementation lives in features/.
///
/// Owns a single [CompositionGeneratorController] for the screen lifetime.
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
