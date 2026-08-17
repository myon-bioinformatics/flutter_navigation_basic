import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/widgets/composition_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Stage 1 songwriting workspace', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompositionStudio(initialBpm: 120, initialKey: 'C'),
          ),
        ),
      ),
    );

    expect(find.text('Composition Studio · C'), findsOneWidget);
    expect(find.text('Visual Metronome'), findsOneWidget);
    expect(find.text('Tap Tempo'), findsOneWidget);
    expect(find.text('Song Structure'), findsOneWidget);
    expect(find.text('Lyrics / Chords'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('metronome can start and stop without leaving a ticker running',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompositionStudio(initialBpm: 120, initialKey: 'C'),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pump();
    expect(find.text('Start'), findsOneWidget);
  });
}
