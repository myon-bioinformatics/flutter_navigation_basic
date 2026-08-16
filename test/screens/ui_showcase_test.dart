import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/ui_showcase_screen.dart';

Future<void> _pumpLoadedShowcase(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: UiShowcaseScreen()));

  // The screen loads JSON through rootBundle and shows an indeterminate progress
  // indicator while waiting. Avoid pumpAndSettle here because that animation can
  // keep scheduling frames under the widget-test fake clock. CI can be much slower
  // than a local run, so give the real async asset load a generous bounded window
  // while still failing instead of hanging forever if loading genuinely stalls.
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }

  await tester.pump();
  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
    reason: 'UI Showcase config did not finish loading within the test window.',
  );
}

void main() {
  testWidgets('UI showcase loads external config and compact navigation',
      (tester) async {
    await _pumpLoadedShowcase(tester);

    expect(find.text('UI Showcase'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);

    expect(find.text('Internal defaults'), findsOneWidget);
    expect(find.text('External JSON overrides'), findsOneWidget);
  });

  testWidgets('UI showcase renders Base64 media with Image.memory',
      (tester) async {
    await _pumpLoadedShowcase(tester);

    final mediaDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Media'),
    );
    await tester.tap(mediaDestination);
    await tester.pump();

    // Image.memory uses a real async codec for the Base64 asset. Give that work
    // a real async turn, then return to the widget-test clock for assertions.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Embedded media'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Video intentionally optional'), findsOneWidget);
  });
}
