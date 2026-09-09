import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/widgets/composition_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpStudio(
  WidgetTester tester, {
  double width = 800,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: await wrapWithDisplayScope(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 1200)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: CompositionStudio(initialBpm: 120, initialKey: 'C'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _selectSubdivision(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _selectSignature(WidgetTester tester, String signature) async {
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(signature).last);
  await tester.pumpAndSettle();
}

TextStyle? _styleForToken(WidgetTester tester, String token) {
  final matches = find.text(token).evaluate().map((e) => e.widget).whereType<Text>();
  for (final text in matches) {
    final weight = text.style?.fontWeight;
    if (weight == FontWeight.w700 || weight == FontWeight.w400) {
      return text.style;
    }
  }
  return null;
}

void main() {
  testWidgets('shows the Stage 1 songwriting workspace', (tester) async {
    await _pumpStudio(tester);

    expect(find.text('Composition Studio · C'), findsOneWidget);
    expect(find.text('Visual Metronome'), findsOneWidget);
    expect(find.text('Tap Tempo'), findsOneWidget);
    expect(find.text('Song Structure'), findsOneWidget);
    expect(find.text('Lyrics / Chords'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('metronome can start and stop without leaving a ticker running',
      (tester) async {
    await _pumpStudio(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pump();
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('highlights subdivision labels instead of a moving arrow',
      (tester) async {
    await _pumpStudio(tester);

    expect(find.textContaining('▲'), findsNothing);
    expect(find.text('1'), findsWidgets);
    expect(find.text('&'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('▲'), findsNothing);
  });

  testWidgets(
      'narrow 4/4 × 4× subdivision labels do not overflow and mark active style',
      (tester) async {
    final captured = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed') ||
          text.contains('A RenderFlex overflowed')) {
        captured.add(details);
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await _pumpStudio(tester, width: 320);
    await _selectSignature(tester, '4/4');
    await _selectSubdivision(tester, '4×');

    expect(find.text('e'), findsWidgets);
    expect(find.text('a'), findsWidgets);
    expect(find.textContaining('▲'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(captured, isEmpty);

    final theme = Theme.of(tester.element(find.byType(CompositionStudio)));
    final idleStyle = _styleForToken(tester, '1');
    expect(idleStyle?.fontWeight, FontWeight.w700);
    expect(idleStyle?.color, theme.colorScheme.primary);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump(const Duration(milliseconds: 50));

    final activeStyle = _styleForToken(tester, '1');
    expect(activeStyle?.fontWeight, FontWeight.w700);
    expect(activeStyle?.color, theme.colorScheme.primary);
    expect(tester.takeException(), isNull);
    expect(captured, isEmpty);
  });

  testWidgets('narrow 3/4 × 4× subdivision labels do not overflow',
      (tester) async {
    final captured = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed') ||
          text.contains('A RenderFlex overflowed')) {
        captured.add(details);
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await _pumpStudio(tester, width: 360);
    await _selectSignature(tester, '3/4');
    await _selectSubdivision(tester, '4×');

    expect(find.text('e'), findsWidgets);
    expect(find.textContaining('▲'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(captured, isEmpty);
  });
}
