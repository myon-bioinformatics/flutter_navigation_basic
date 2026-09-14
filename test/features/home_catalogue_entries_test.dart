import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/core/navigation/app_navigation.dart';
import 'package:flutter_application_1/features/home/presentation/home_screen.dart';
import 'package:flutter_application_1/screens/hub_screen.dart';
import 'package:flutter_application_1/screens/mcp_integration_screen.dart';
import 'package:flutter_application_1/screens/mock_api_screen.dart';
import 'package:flutter_application_1/screens/ui_showcase_screen.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> routes,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    await wrapWithDisplayScope(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: routes,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(HomeScreen), findsOneWidget);
}

Future<void> _openEntry(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> routes,
  required String label,
  required Type pageType,
}) async {
  await _pumpHome(tester, routes: routes);
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  // Hub loads catalogue assets asynchronously; avoid pumpAndSettle hangs.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(pageType), findsOneWidget);
}

void main() {
  const entries = <(String, Type)>[
    ('Navigation Hub', HubScreen),
    ('UI Showcase', UiShowcaseScreen),
    ('API Integration', ApiIntegrationScreen),
    ('MCP Integration', McpIntegrationScreen),
  ];

  testWidgets('feature Home exposes Hub, Showcase, API, and MCP labels',
      (tester) async {
    await _pumpHome(tester, routes: AppRoutes.routes);

    for (final entry in entries) {
      expect(find.text(entry.$1), findsOneWidget);
    }
  });

  for (final entry in entries) {
    testWidgets('public Home opens ${entry.$1}', (tester) async {
      await _openEntry(
        tester,
        routes: AppRoutes.routes,
        label: entry.$1,
        pageType: entry.$2,
      );
    });

    testWidgets('prod Home opens ${entry.$1}', (tester) async {
      await _openEntry(
        tester,
        routes: AppNavigation.routes,
        label: entry.$1,
        pageType: entry.$2,
      );
    });
  }
}
