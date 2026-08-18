import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/mock_api_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/display_test_harness.dart';

void main() {
  // Scenario buttons trigger a real network fetch via MockApiClient, which has
  // no fixture/mock in this suite and would hang or fail in a sandboxed CI
  // environment without egress. These tests only cover the static catalog
  // chrome rendered before any scenario is run.
  testWidgets('renders catalog chrome for the default (no scenario run) state', (tester) async {
    final controller = await loadTestDisplayController();
    await tester.pumpWidget(
      MaterialApp(
        home: DisplayScope(controller: controller, child: const ApiIntegrationScreen()),
      ),
    );

    expect(find.text('External Integration · API'), findsOneWidget);
    expect(find.text('API Demo'), findsOneWidget);
    expect(find.text('Choose an API scenario.'), findsOneWidget);
    expect(find.text('Timeout'), findsOneWidget);
    expect(find.textContaining('Mock: '), findsOneWidget);
  });

  testWidgets('renders translated chrome for a non-English display locale', (tester) async {
    SharedPreferences.setMockInitialValues({DisplayController.preferenceKey: 'ja'});
    final controller = await DisplayController.load();

    await tester.pumpWidget(
      MaterialApp(
        home: DisplayScope(controller: controller, child: const ApiIntegrationScreen()),
      ),
    );

    expect(find.text('APIデモ'), findsOneWidget);
    expect(find.text('APIシナリオを選択してください。'), findsOneWidget);
    expect(find.text('タイムアウト'), findsOneWidget);
  });
}
