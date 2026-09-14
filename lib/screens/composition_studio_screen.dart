import 'package:flutter/material.dart';

import '../features/composition_generator/domain/composition_generator_controller.dart';
import '../features/composition_generator/presentation/composition_generator_page.dart';

/// Thin public wrapper; implementation lives in features/.
class CompositionStudioScreen extends StatelessWidget {
  const CompositionStudioScreen({super.key});

  @override
  Widget build(BuildContext context) => CompositionGeneratorPage(
        controller: CompositionGeneratorController(),
      );
}
