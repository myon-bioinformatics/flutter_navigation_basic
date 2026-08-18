import 'dart:math';

import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../data/composer.dart';
import '../shared/display/display_scope.dart';
import '../shared/widgets/chord_theory_card.dart';
import '../shared/widgets/composition_studio.dart';
import '../shared/widgets/note_sequence_card.dart';
import '../widgets/nav_button.dart';

class CompositionStudioScreen extends StatefulWidget {
  const CompositionStudioScreen({super.key});

  @override
  State<CompositionStudioScreen> createState() => _CompositionStudioScreenState();
}

class _CompositionStudioScreenState extends State<CompositionStudioScreen> {
  late final String _initialKey;
  late final int _initialBpm;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _initialKey = Composer.diatonicScaleList[
      random.nextInt(Composer.diatonicScaleList.length)
    ];
    _initialBpm = 90 + random.nextInt(61);
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('compositionGenerator.title')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompositionStudio(
                  initialBpm: _initialBpm,
                  initialKey: _initialKey,
                ),
                const SizedBox(height: 16),
                ChordTheoryCard(initialKey: _initialKey),
                const SizedBox(height: 16),
                const NoteSequenceCard(),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(
                      label: display.text('compositionStudio.songSeedGenerator'),
                      routeName: AppRoutes.compositionSeedGenerator,
                    ),
                    NavButton(label: display.text('home.title'), routeName: AppRoutes.home),
                    NavButton(label: display.text('nav.counterPlayground'), routeName: AppRoutes.counterPlayground),
                    NavButton(label: display.text('nav.ironyGenerator'), routeName: AppRoutes.ironyGenerator),
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
