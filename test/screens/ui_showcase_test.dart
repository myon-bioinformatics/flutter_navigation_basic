import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/ui_showcase_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpLoadedShowcase(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: await wrapWithDisplayScope(const UiShowcaseScreen())),
  );

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
  testWidgets('UI showcase loads config, compact navigation, and Base64 media',
      (tester) async {
    await _pumpLoadedShowcase(tester);

    expect(find.text('UI Showcase'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Internal defaults'), findsOneWidget);
    expect(find.text('External JSON overrides'), findsOneWidget);

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);

    scaffoldState.closeDrawer();
    await tester.pumpAndSettle();

    final mediaDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Media'),
    );
    await tester.tap(mediaDestination);
    await tester.pump();

    // Let Image.memory resolve its codec before checking the media page.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Embedded media'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // The media page is a lazily built ListView. Scroll the trailing ListTile into
    // view before asserting it instead of assuming the test viewport is tall enough.
    final videoOptional = find.text('Video intentionally optional');
    await tester.scrollUntilVisible(
      videoOptional,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(videoOptional, findsOneWidget);
  });

  testWidgets('renders translated chrome for a non-English display locale',
      (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'ja'},
    );
    expect(controller.locale, 'ja');

    await tester.pumpWidget(
      MaterialApp(
        home: DisplayScope(
          controller: controller,
          child: const UiShowcaseScreen(),
        ),
      ),
    );
    for (var attempt = 0; attempt < 200; attempt++) {
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    }
    await tester.pump();

    // Assert translated chrome that is always mounted in the app bar rather than
    // body chips whose presence can depend on the current viewport/transition.
    expect(find.byTooltip('デザインスタイル'), findsOneWidget);
    expect(find.byTooltip('明るさ'), findsOneWidget);
    expect(find.byTooltip('ホーム'), findsOneWidget);
  });
}
