import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/navigation/app_tools.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('ToolDoorSelector lists tools and skips current route', (tester) async {
    final navigated = <String>[];
    final tools = [
      AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
        navigate: () => navigated.add(RouteNames.photoStudio),
      ),
      AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
        navigate: () => navigated.add(RouteNames.coordinateTool),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          Scaffold(
            body: ToolDoorSelector(
              currentRouteName: RouteNames.photoStudio,
              tools: tools,
            ),
          ),
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
  });

  testWidgets('beforeNavigate can cancel door navigation', (tester) async {
    final navigated = <String>[];
    final tools = [
      AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
        navigate: () => navigated.add(RouteNames.photoStudio),
      ),
      AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
        navigate: () => navigated.add(RouteNames.coordinateTool),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          Scaffold(
            body: ToolDoorSelector(
              currentRouteName: RouteNames.photoStudio,
              tools: tools,
              beforeNavigate: () async => false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latitude / Longitude').last);
    await tester.pumpAndSettle();
    expect(navigated, isEmpty);
  });
}
