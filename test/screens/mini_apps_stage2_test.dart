import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/composition_generator_screen.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/irony_generator_screen.dart';

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

  testWidgets('irony favorites can be managed from the favorites card',
      (tester) async {
    await tester.pumpWidget(await _app(const IronyGeneratorScreen()));

    await tester.tap(find.text('Favorite'));
    await tester.pump();
    expect(find.text('Favorites · 1'), findsOneWidget);

    final removeButton = find.byTooltip('Remove favorite');
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pump();

    expect(find.text('Favorites · 0'), findsOneWidget);
    expect(find.text('Favorite an irony to keep it handy here.'), findsOneWidget);
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

  testWidgets('composition save current confirms the action', (tester) async {
    await tester.pumpWidget(await _app(const CompositionGeneratorScreen()));

    await tester.tap(find.text('Save current'));
    await tester.pump();

    expect(
      find.text('Composition idea saved to recent ideas'),
      findsOneWidget,
    );
  });
}
