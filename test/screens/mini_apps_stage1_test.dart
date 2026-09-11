import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/composition_generator_screen.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/irony_generator_screen.dart';

import '../support/display_test_harness.dart';

Future<Widget> _app(Widget child) async =>
    MaterialApp(home: await wrapWithDisplayScope(child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('counter supports step selection, increase, decrease and reset',
      (tester) async {
    await tester.pumpWidget(await _app(const CounterPlaygroundScreen()));

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
    await tester.pump();
    expect(find.text('5'), findsWidgets);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('0'), findsWidgets);
    expect(find.text('Keep experimenting 👾'), findsOneWidget);
  });

  testWidgets('irony generator exposes filters and repeat actions',
      (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
    expect(find.text('Generate again'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);

    await tester.tap(find.text('Favorite'));
    await tester.pump();
    expect(find.text('Favorited'), findsOneWidget);
    expect(find.text('Favorites · 1'), findsOneWidget);
  });

  testWidgets('irony recent generations can be removed with the close button',
      (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));

    await tester.tap(find.text('Generate again'));
    await tester.pump();

    // Only non-current history rows expose the remove button.
    expect(find.byTooltip('Remove from recent'), findsOneWidget);

    final removeButton = find.byTooltip('Remove from recent');
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pump();

    // Only the current entry remains.
    expect(find.byTooltip('Remove from recent'), findsNothing);
  });

  testWidgets('irony copy shows snackbar confirmation', (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));

    await tester.tap(find.byTooltip('Copy irony'));
    await tester.pump();

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('composition generator exposes richer song seed controls',
      (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));

    expect(find.text('Song seed'), findsOneWidget);
    expect(find.text('Generate again'), findsOneWidget);
    expect(find.text('Shuffle chords'), findsOneWidget);
    expect(find.text('Recent ideas'), findsOneWidget);

    await tester.tap(find.text('Generate again'));
    await tester.pump();
    expect(find.byIcon(Icons.music_note), findsWidgets);
  });

  testWidgets('composition copy shows snackbar confirmation', (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));

    await tester.tap(find.byTooltip('Copy composition idea'));
    await tester.pump();

    expect(find.text('Composition idea copied'), findsOneWidget);
  });
}
