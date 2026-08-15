import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/composition_generator_screen.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/irony_generator_screen.dart';

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('counter supports step selection, increase, decrease and reset',
      (tester) async {
    await tester.pumpWidget(_app(const CounterPlaygroundScreen()));

    expect(find.text('Current value'), findsOneWidget);
    expect(find.text('Step 5'), findsOneWidget);

    await tester.tap(find.text('Step 5'));
    await tester.tap(find.text('Increase'));
    await tester.pump();
    expect(find.text('5'), findsWidgets);

    await tester.tap(find.text('Decrease'));
    await tester.pump();
    expect(find.text('0'), findsWidgets);

    await tester.tap(find.text('Increase'));
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('Keep experimenting 👾'), findsOneWidget);
  });

  testWidgets('irony generator exposes filters and repeat actions',
      (tester) async {
    await tester.pumpWidget(_app(const IronyGeneratorScreen()));

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
    expect(find.text('Generate again'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);

    await tester.tap(find.text('Favorite'));
    await tester.pump();
    expect(find.text('Favorited'), findsOneWidget);
    expect(find.textContaining('1 favorite'), findsOneWidget);
  });

  testWidgets('composition generator exposes richer song seed controls',
      (tester) async {
    await tester.pumpWidget(_app(const CompositionGeneratorScreen()));

    expect(find.text('Song seed'), findsOneWidget);
    expect(find.text('Generate again'), findsOneWidget);
    expect(find.text('Shuffle chords'), findsOneWidget);
    expect(find.text('Recent ideas'), findsOneWidget);

    await tester.tap(find.text('Generate again'));
    await tester.pump();
    expect(find.byIcon(Icons.music_note), findsWidgets);
  });
}
