import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/composition_generator_screen.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/irony_generator_screen.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';

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

  testWidgets('irony generator exposes Door and selectable drag card',
      (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
  });

  testWidgets('composition generator exposes richer song seed controls',
      (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));

    expect(find.text('Song Seed Generator'), findsOneWidget);
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
