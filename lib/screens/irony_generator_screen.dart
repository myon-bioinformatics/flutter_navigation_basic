import 'package:flutter/material.dart';

import '../features/irony_generator/domain/irony_generator_controller.dart';
import '../features/irony_generator/presentation/irony_generator_page.dart';

/// Thin public wrapper; implementation lives in features/.
///
/// Creates one [IronyGeneratorController] for the screen lifetime and
/// transfers ownership to [IronyGeneratorPage] (the page disposes it).
class IronyGeneratorScreen extends StatefulWidget {
  const IronyGeneratorScreen({super.key});

  @override
  State<IronyGeneratorScreen> createState() => _IronyGeneratorScreenState();
}

class _IronyGeneratorScreenState extends State<IronyGeneratorScreen> {
  late final IronyGeneratorController _controller = IronyGeneratorController();

  @override
  Widget build(BuildContext context) =>
      IronyGeneratorPage(controller: _controller);
}
