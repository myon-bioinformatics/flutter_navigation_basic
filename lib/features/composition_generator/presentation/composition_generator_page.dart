import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/chord_theory_card.dart';
import '../../../shared/widgets/composition_studio.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/note_sequence_card.dart';
import '../domain/composition_generator_controller.dart';

class CompositionGeneratorPage extends StatelessWidget {
  const CompositionGeneratorPage({super.key, required this.controller});

  final CompositionGeneratorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Composition Studio 🎸'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompositionStudio(
                  initialBpm: controller.bpm,
                  initialKey: controller.tonicKey,
                ),
                const SizedBox(height: 16),
                ChordTheoryCard(initialKey: controller.tonicKey),
                const SizedBox(height: 16),
                const NoteSequenceCard(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomButton(label: 'Home 🏠', onPressed: AppNavigation.toHome),
                    CustomButton(
                      label: 'Counter Playground 👾',
                      onPressed: AppNavigation.toCounterPlayground,
                    ),
                    CustomButton(
                      label: 'Irony Generator 🥐',
                      onPressed: AppNavigation.toIronyGenerator,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
