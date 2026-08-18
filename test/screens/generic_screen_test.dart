import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpGeneric(
  WidgetTester tester,
  int screenId, {
  DisplayController? controller,
}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(
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
    await _pumpGeneric(tester, 3);

    expect(find.text('Back to Hub'), findsWidgets);
    expect(find.textContaining('Navigation:'), findsOneWidget);
    expect(find.textContaining('API:'), findsOneWidget);
    expect(find.textContaining('Theme:'), findsOneWidget);
    expect(find.textContaining('Data:'), findsOneWidget);
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
    SharedPreferences.setMockInitialValues({DisplayController.preferenceKey: 'ja'});
    final controller = await DisplayController.load();

    await _pumpGeneric(tester, 3, controller: controller);

    expect(find.text('ハブに戻る'), findsWidgets);
    expect(find.textContaining('ナビゲーション:'), findsOneWidget);
  });
}
