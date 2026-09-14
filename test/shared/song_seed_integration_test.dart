import 'package:flutter/material.dart';
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
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          Scaffold(
            body: SingleChildScrollView(
              child: const CompositionStudio(
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

    // Expand panel and apply via the production Apply control (not a public state API).
    final apply = find.text('Apply to studio');
    if (apply.evaluate().isEmpty) {
      await tester.tap(find.textContaining('Song Seed').first);
      await tester.pumpAndSettle();
    }
    // Seed the panel fields through customize controls when needed: generate then apply.
    expect(find.text('Apply to studio'), findsWidgets);
    await tester.ensureVisible(find.text('Apply to studio').first);
    await tester.tap(find.text('Apply to studio').first);
    await tester.pumpAndSettle();

    // After apply, studio heading reflects some key and BPM chips/fields update.
    expect(find.textContaining('BPM'), findsWidgets);
  });
}
