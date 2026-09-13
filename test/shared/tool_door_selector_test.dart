import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/navigation/app_tools.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

Widget _doorHost({
  required List<AppTool> tools,
  required Map<String, WidgetBuilder> routes,
  Future<bool> Function()? beforeNavigate,
}) {
  return MaterialApp(
    initialRoute: RouteNames.photoStudio,
    routes: {
      ...routes,
      RouteNames.photoStudio: (_) => Scaffold(
            body: ToolDoorSelector(
              currentRouteName: RouteNames.photoStudio,
              tools: tools,
              beforeNavigate: beforeNavigate,
            ),
          ),
    },
  );
}

void main() {
  testWidgets('ToolDoorSelector lists tools and skips current route',
      (tester) async {
    final navigated = <String>[];
    final tools = [
      const AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
      ),
      const AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
      ),
    ];

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        _doorHost(
          tools: tools,
          routes: {
            RouteNames.coordinateTool: (_) {
              navigated.add(RouteNames.coordinateTool);
              return const Scaffold(body: Text('coordinate-dest'));
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('Photo Studio'), findsWidgets);
    await tester.tap(find.text('Latitude / Longitude').last);
    await tester.pumpAndSettle();
    expect(navigated, [RouteNames.coordinateTool]);
    expect(find.text('coordinate-dest'), findsOneWidget);
  });

  testWidgets('beforeNavigate can cancel door navigation', (tester) async {
    final navigated = <String>[];
    final tools = [
      const AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
      ),
      const AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
      ),
    ];

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        _doorHost(
          tools: tools,
          beforeNavigate: () async => false,
          routes: {
            RouteNames.coordinateTool: (_) {
              navigated.add(RouteNames.coordinateTool);
              return const Scaffold(body: Text('coordinate-dest'));
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latitude / Longitude').last);
    await tester.pumpAndSettle();
    expect(navigated, isEmpty);
    expect(find.text('coordinate-dest'), findsNothing);
  });

  testWidgets('home door uses pushNamedAndRemoveUntil', (tester) async {
    final tools = [
      const AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
      ),
      const AppTool(
        routeName: RouteNames.home,
        labelKey: 'home.title',
      ),
    ];

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        _doorHost(
          tools: tools,
          routes: {
            RouteNames.home: (_) => const Scaffold(body: Text('home-dest')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Home').last);
    await tester.pumpAndSettle();

    expect(find.text('home-dest'), findsOneWidget);
    // Stack cleared — photo studio host is gone.
    expect(find.byType(ToolDoorSelector), findsNothing);
  });

  testWidgets('Navigator.of works without AppNavigation.navigatorKey',
      (tester) async {
    // Mirrors main.dart: routes map only, no global navigatorKey.
    final tools = appTools
        .where(
          (t) =>
              t.routeName == RouteNames.photoStudio ||
              t.routeName == RouteNames.coordinateTool,
        )
        .toList();

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        MaterialApp(
          initialRoute: RouteNames.photoStudio,
          routes: {
            RouteNames.photoStudio: (_) => Scaffold(
                  body: ToolDoorSelector(
                    currentRouteName: RouteNames.photoStudio,
                    tools: tools,
                  ),
                ),
            RouteNames.coordinateTool: (_) =>
                const Scaffold(body: Text('coord-via-navigator')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latitude / Longitude').last);
    await tester.pumpAndSettle();
    expect(find.text('coord-via-navigator'), findsOneWidget);
  });
}
