import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/composition_generator/domain/song_seed.dart';
import 'package:flutter_application_1/features/composition_generator/domain/song_seed_generator.dart';
import 'package:flutter_application_1/shared/widgets/composition_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

void main() {
  test('SongSeedGenerator produces valid seeds', () {
    final generator = SongSeedGenerator();
    final first = generator.generate();
    final second = generator.generate(avoid: first);
    expect(first.tonicKey, isNotEmpty);
    expect(second.bpm, inInclusiveRange(80, 160));
    expect(generator.progressionPoolFor('Major'), isNotEmpty);
    expect(generator.progressionPoolFor('Minor'), isNotEmpty);
  });

  testWidgets('CompositionStudio applies song seed into BPM and chords', (tester) async {
    final key = GlobalKey<CompositionStudioState>();
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          Scaffold(
            body: SingleChildScrollView(
              child: CompositionStudio(
                key: key,
                initialBpm: 100,
                initialKey: 'C',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Song Seed'), findsWidgets);

    key.currentState!.applySongSeed(
      const SongSeed(
        tonicKey: 'G',
        mode: 'Major',
        bpm: 128,
        timeSignature: '3/4',
        progression: 'I – V – vi – IV',
      ),
    );
    await tester.pump();

    expect(find.text('128'), findsWidgets);
    expect(find.text('I – V – vi – IV'), findsOneWidget);
  });
}
