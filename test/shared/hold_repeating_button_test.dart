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

  testWidgets(
      'drag-off after hold does not suppress the next semantics tap',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HoldRepeatingButton(
                onPressed: () => count++,
                icon: const Icon(Icons.add),
                label: const Text('Increase'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.press(find.text('Increase'));
      await tester.pump(HoldRepeatingButton.holdDelay);
      await tester.pump(HoldRepeatingButton.holdInterval);
      expect(count, greaterThanOrEqualTo(1));

      // Move outside the button then release so Material cancels the tap.
      await gesture.moveBy(const Offset(0, 400));
      await gesture.up();
      await tester.pump();
      await tester.pump(); // post-frame sticky clear

      final afterDragOff = count;
      tester.semantics.tap(find.semantics.byLabel('Increase'));
      await tester.pump();
      expect(count, afterDragOff + 1);
    } finally {
      handle.dispose();
    }
  });
}
