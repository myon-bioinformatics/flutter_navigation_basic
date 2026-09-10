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

  testWidgets('holding repeats onPressed', (tester) async {
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
    expect(count, 1);

    await tester.pump(HoldRepeatingButton.holdDelay);
    await tester.pump(HoldRepeatingButton.holdInterval);
    await tester.pump(HoldRepeatingButton.holdInterval);
    expect(count, greaterThanOrEqualTo(3));

    await gesture.up();
    await tester.pump();
    final afterRelease = count;
    await tester.pump(HoldRepeatingButton.holdInterval * 2);
    expect(count, afterRelease);
  });
}
