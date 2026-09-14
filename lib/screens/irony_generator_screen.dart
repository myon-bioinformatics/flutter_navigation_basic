import 'package:flutter/material.dart';

import '../features/irony_generator/domain/irony_generator_controller.dart';
import '../features/irony_generator/presentation/irony_generator_page.dart';

/// Thin public wrapper; implementation lives in features/.
class IronyGeneratorScreen extends StatelessWidget {
  const IronyGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) => IronyGeneratorPage(
        controller: IronyGeneratorController(),
      );
}
