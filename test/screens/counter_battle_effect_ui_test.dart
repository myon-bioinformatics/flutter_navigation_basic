import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('positive counter shows damage orbs and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CounterPlaygroundScreen())),
    );

    await tester.tap(find.text('Increase'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('💥 Damage 1'), findsOneWidget);
    expect(find.textContaining('🔥'), findsOneWidget);
  });

  testWidgets('negative counter shows heal orbs and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CounterPlaygroundScreen())),
    );

    await tester.tap(find.text('Decrease'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('💚 Heal 1'), findsOneWidget);
    expect(find.textContaining('❤️'), findsOneWidget);
  });
}
