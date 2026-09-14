import 'package:flutter/material.dart';

import '../../../core/navigation/route_names.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/chord_theory_card.dart';
import '../../../shared/widgets/composition_studio.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/note_sequence_card.dart';
import '../../../shared/widgets/tool_door_selector.dart';
import '../domain/composition_generator_controller.dart';

class CompositionGeneratorPage extends StatefulWidget {
  const CompositionGeneratorPage({super.key, required this.controller});

  final CompositionGeneratorController controller;

  @override
  State<CompositionGeneratorPage> createState() =>
      _CompositionGeneratorPageState();
}

class _CompositionGeneratorPageState extends State<CompositionGeneratorPage> {
  late String _theoryKey = widget.controller.tonicKey;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: display.text('compositionGenerator.title')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompositionStudio(
                  initialBpm: widget.controller.bpm,
                  initialKey: widget.controller.tonicKey,
                  onKeyChanged: (key) => setState(() => _theoryKey = key),
                ),
                const SizedBox(height: 16),
                ChordTheoryCard(initialKey: _theoryKey),
                const SizedBox(height: 16),
                const NoteSequenceCard(),
                const SizedBox(height: 24),
                const ToolDoorSelector(
                  currentRouteName: RouteNames.compositionGenerator,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
