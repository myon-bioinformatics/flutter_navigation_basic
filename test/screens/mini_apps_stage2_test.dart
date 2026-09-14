import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/composition_generator_screen.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/irony_generator_screen.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';

import '../support/display_test_harness.dart';

Future<Widget> _app(Widget child) async =>
    MaterialApp(home: await wrapWithDisplayScope(child));

void main() {
  testWidgets('counter can undo the latest value change', (tester) async {
    await tester.pumpWidget(await _app(const CounterPlaygroundScreen()));

    await tester.tap(find.text('Step 5'));
    await tester.tap(find.text('Increase'));
    await tester.pump();
    expect(find.text('5'), findsWidgets);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('irony generator keeps Door while drag card is present',
      (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
  });

  testWidgets('composition exposes standard Flutter customization controls',
      (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));

    final customize = find.text('Customize seed');
    await tester.ensureVisible(customize);
    await tester.tap(customize);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4));
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);
  });

  testWidgets('composition seed panel has no no-op Save current control',
      (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));
    await tester.pumpAndSettle();

    // Legacy host embeds SongSeedPanel without onApply; the old no-op
    // "Save current" control was removed so only real actions remain.
    expect(find.text('Save current'), findsNothing);
    expect(find.text('Customize seed'), findsOneWidget);
    expect(find.byTooltip('Copy composition idea'), findsOneWidget);
  });
}
