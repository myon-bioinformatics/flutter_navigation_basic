import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/now_timeline/presentation/now_timeline_page.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders text from the app-wide display locale, not a screen-local store', (tester) async {
    SharedPreferences.setMockInitialValues({
      DisplayController.preferenceKey: 'ja',
    });
    final controller = await DisplayController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: DisplayScope(controller: controller, child: const NowTimelinePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人・場所・予定・イベントを1本の時間軸にまとめます。'), findsOneWidget);
  });

  testWidgets('switching locale via the shared picker updates the page and does not touch the legacy key', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await DisplayController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: DisplayScope(controller: controller, child: const NowTimelinePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('People, places, schedules and events on one shared timeline.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JA').last);
    await tester.pumpAndSettle();

    expect(find.text('人・場所・予定・イベントを1本の時間軸にまとめます。'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DisplayController.preferenceKey), 'ja');
    expect(prefs.getString(DisplayController.legacyNowTimelinePreferenceKey), isNull);
  });
}
