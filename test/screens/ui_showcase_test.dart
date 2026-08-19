import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/ui_showcase_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpLoadedShowcase(
  WidgetTester tester, {
  DisplayController? controller,
}) async {
  final scopedShowcase = controller == null
      ? await wrapWithDisplayScope(const UiShowcaseScreen())
      : DisplayScope(
          controller: controller,
          child: const UiShowcaseScreen(),
        );

  await tester.pumpWidget(MaterialApp(home: scopedShowcase));

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
  testWidgets(
      'UI showcase loads config, compact navigation, Base64 media, and translated chrome',
      (tester) async {
    final controller = await loadTestDisplayController();
    await _pumpLoadedShowcase(tester, controller: controller);

    expect(find.text('UI Showcase'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Internal defaults'), findsOneWidget);
    expect(find.text('External JSON overrides'), findsOneWidget);

    Finder popupMenuForIcon(IconData icon) => find.ancestor(
          of: find.byIcon(icon),
          matching: find.byWidgetPredicate(
            (widget) => widget is PopupMenuButton<String>,
          ),
        );

    await tester.runAsync(() => controller.setLocale('ja'));
    await tester.pump();
    expect(controller.locale, 'ja');

    final styleMenu = tester.widget<PopupMenuButton<String>>(
      popupMenuForIcon(Icons.palette_outlined),
    );
    expect(
      styleMenu.tooltip,
      controller.text('uiShowcase.designStyleTooltip'),
    );

    final brightnessMenu = tester.widget<PopupMenuButton<String>>(
      popupMenuForIcon(Icons.brightness_6_outlined),
    );
    expect(
      brightnessMenu.tooltip,
      controller.text('uiShowcase.brightnessTooltip'),
    );

    final homeButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.home_outlined),
        matching: find.byWidgetPredicate((widget) => widget is IconButton),
      ),
    );
    expect(
      homeButton.tooltip,
      controller.text('uiShowcase.homeTooltip'),
    );

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
}
