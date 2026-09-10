import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/hold_repeating_button.dart';

void main() {
  testWidgets('tap fires onPressed once', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldRepeatingButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            label: const Text('Increase'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Increase'));
    await tester.pump();
    expect(count, 1);
  });

  testWidgets('semantics tap fires onPressed once', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoldRepeatingButton(
              onPressed: () => count++,
              icon: const Icon(Icons.add),
              label: const Text('Increase'),
            ),
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Increase'));
      await tester.pump();
      expect(count, 1);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('holding repeats onPressed without trailing double-fire',
      (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldRepeatingButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            label: const Text('Increase'),
          ),
        ),
      ),
    );

    final gesture = await tester.press(find.text('Increase'));
    await tester.pump();
    // Material tap has not completed yet; repeat has not started.
    expect(count, 0);

    await tester.pump(HoldRepeatingButton.holdDelay);
    expect(count, greaterThanOrEqualTo(1));

    await tester.pump(HoldRepeatingButton.holdInterval);
    await tester.pump(HoldRepeatingButton.holdInterval);
    expect(count, greaterThanOrEqualTo(3));

    await gesture.up();
    await tester.pumpAndSettle();
    final afterRelease = count;
    await tester.pump(HoldRepeatingButton.holdInterval * 2);
    // Release must not add an extra Material tap on top of hold repeats.
    expect(count, afterRelease);
  });
}
