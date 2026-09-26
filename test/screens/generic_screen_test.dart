import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpGeneric(
  WidgetTester tester,
  int screenId, {
  DisplayController? controller,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(
      routes: routes,
      home: DisplayScope(controller: resolvedController, child: GenericScreen(screenId: screenId)),
    ),
  );
  // GenericScreen loads assets/screens.json asynchronously; wait for the spinner to clear.
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }
  await tester.pump();
}

void main() {
  testWidgets('non-detail screen shows translated Back-to-Hub and pattern chips', (tester) async {
    // Screen 3 is in the "realtime" domain, which has no ScreenDetail payload.
    // Its raw description sentence ("Navigation: BasicReplace, API: HttpPut, ...")
    // also renders on the page, so match the exact pattern-chip text rather than
    // a substring that both the chip and the description sentence contain.
    await _pumpGeneric(tester, 3);

    expect(find.text('Back to Hub'), findsWidgets);
    expect(find.byKey(const Key('back-to-hub')), findsOneWidget);
    expect(find.text('Navigation: BasicReplace'), findsOneWidget);
    expect(find.text('API: HttpPut'), findsOneWidget);
    expect(find.text('Theme: TextButton'), findsOneWidget);
    expect(find.text('Data: FilterNested'), findsOneWidget);
  });

  testWidgets('Back to Hub is tappable and navigates', (tester) async {
    await _pumpGeneric(
      tester,
      3,
      routes: {
        AppRoutes.hub: (_) => const Scaffold(body: Text('Hub route reached')),
      },
    );

    final backToHub = find.byKey(const Key('back-to-hub'));
    expect(backToHub, findsOneWidget);
    await tester.tap(backToHub, warnIfMissed: true);
    await tester.pumpAndSettle();

    expect(find.text('Hub route reached'), findsOneWidget);
  });

  // Same-node contract for #97/#99: identifier, tap, and label must share
  // the Key-backed semantics node (fix A / excludeSemantics).
  testWidgets('Back to Hub semantics keep identifier with tap', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await _pumpGeneric(tester, 3);
      final node = tester.getSemantics(find.byKey(const Key('back-to-hub')));
      final data = node.getSemanticsData();
      expect(node.identifier, 'back-to-hub');
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
      expect(data.hasFlag(SemanticsFlag.isFocusable), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);
      expect(node.label, 'Back to Hub');
      var children = 0;
      node.visitChildren((_) {
        children++;
        return true;
      });
      expect(children, 0, reason: 'excludeSemantics must not leave a second tappable child');
    } finally {
      handle.dispose();
    }
  });

  testWidgets('detail screen shows translated tab labels and use-case section headers', (tester) async {
    // Screen 1 is in the "integration" domain, which carries a ScreenDetail payload.
    await _pumpGeneric(tester, 1);

    expect(find.text('Use case'), findsOneWidget);
    expect(find.text('UI sample'), findsOneWidget);

    await tester.tap(find.text('Use case'));
    await tester.pumpAndSettle();

    expect(find.text('Purpose'), findsOneWidget);
    expect(find.text('When to use'), findsOneWidget);
    expect(find.text('Design points'), findsOneWidget);
    expect(find.text('Pitfall'), findsOneWidget);
    expect(find.text('Snippet'), findsOneWidget);
  });

  testWidgets('renders translated chrome for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'jpn'},
    );

    await _pumpGeneric(tester, 3, controller: controller);

    expect(find.text('ハブに戻る'), findsWidgets);
    expect(find.text('ナビゲーション: BasicReplace'), findsOneWidget);
  });
}
