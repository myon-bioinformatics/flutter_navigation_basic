import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpHome(WidgetTester tester, {DisplayController? controller}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(
      home: DisplayScope(controller: resolvedController, child: const HomeScreen()),
    ),
  );
}

void main() {
  testWidgets('renders catalog-driven action cards and a weekday-aware date', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Home 🏠'), findsOneWidget);
    expect(find.text('Navigation Hub'), findsOneWidget);
    expect(find.text('Browse the 198 navigation catalogue screens.'), findsOneWidget);

    final now = DateTime.now();
    const englishWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final expectedWeekday = englishWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });

  testWidgets('renders translated chrome and weekday for a non-English display locale', (tester) async {
    SharedPreferences.setMockInitialValues({DisplayController.preferenceKey: 'ja'});
    final controller = await DisplayController.load();

    await _pumpHome(tester, controller: controller);

    expect(find.text('ホーム 🏠'), findsOneWidget);
    expect(find.text('Navigation Hub'), findsOneWidget);
    expect(find.text('198件のナビゲーションカタログ画面を閲覧します。'), findsOneWidget);

    final now = DateTime.now();
    const japaneseWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final expectedWeekday = japaneseWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });
}
