import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/home/domain/home_controller.dart';
import 'package:flutter_application_1/features/home/presentation/home_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../../../support/display_test_harness.dart';

Future<void> _pumpHome(WidgetTester tester, {DisplayController? controller}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(
      home: DisplayScope(
        controller: resolvedController,
        child: HomeScreen(controller: HomeController()),
      ),
    ),
  );
}

void main() {
  testWidgets('renders catalog-driven action cards and a weekday-aware date', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Home 🏠'), findsOneWidget);
    expect(find.text('URL Parameters'), findsOneWidget);
    expect(find.text('Inspect route/query-style parameter handling.'), findsOneWidget);

    final now = DateTime.now();
    const englishWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final expectedWeekday = englishWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });

  testWidgets('renders translated chrome and weekday for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'ja'},
    );

    await _pumpHome(tester, controller: controller);

    expect(find.text('ホーム 🏠'), findsOneWidget);
    expect(find.text('URL Parameters'), findsOneWidget);
    expect(find.text('ルート/クエリ形式のパラメータ処理を確認します。'), findsOneWidget);

    final now = DateTime.now();
    const japaneseWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final expectedWeekday = japaneseWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });
}
