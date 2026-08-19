import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/hub_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpHub(WidgetTester tester, {DisplayController? controller}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(home: DisplayScope(controller: resolvedController, child: const HubScreen())),
  );
  // Hub loads assets/screens.json asynchronously; wait for the spinner to clear.
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
  testWidgets('renders catalog chrome and toggles list/grid view', (tester) async {
    await _pumpHub(tester);

    expect(find.text('Navigation Hub 🗺️'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.byTooltip('List view'));
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);

    expect(find.byTooltip('External Integration · API'), findsOneWidget);
    expect(find.byTooltip('External Integration · MCP'), findsOneWidget);
  });

  testWidgets('renders translated chrome for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'ja'},
    );

    await _pumpHub(tester, controller: controller);

    expect(find.text('ナビゲーションハブ 🗺️'), findsOneWidget);
    expect(find.byTooltip('リスト表示'), findsOneWidget);
    expect(find.byTooltip('グリッド表示'), findsOneWidget);
  });
}
