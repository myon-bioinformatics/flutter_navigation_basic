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

// The FormField takes items as a constructor argument but exposes no items
// getter. Inspect the public DropdownButton actually built inside the Door.
Finder _doorDropdown() => find.descendant(
      of: find.byType(ToolDoorSelector),
      matching: find.byType(DropdownButton<String>),
    );

DropdownButton<String> _dropdown(WidgetTester tester) =>
    tester.widget<DropdownButton<String>>(_doorDropdown());

void main() {
  setUp(() => HomeDoorCatalog.instance.clearDiscoveries());
  tearDown(() => HomeDoorCatalog.instance.clearDiscoveries());

  test('discovery catalogue rejects unknown IDs, duplicates, and non-Home routes', () {
    HomeDoorCatalog.instance.updateDiscoveries(const [
      AppTool(routeName: '/screen138', label: 'Screen138 · first draw'),
      AppTool(routeName: '/screen138', label: 'duplicate'),
      AppTool(routeName: '/screen5', label: 'old fixed route'),
      AppTool(routeName: '/screen199', label: 'out of range'),
      AppTool(routeName: '/screen80', label: 'Screen80 · second'),
      AppTool(routeName: '/screen87', label: 'Screen87 · third'),
      AppTool(routeName: '/screen75', label: 'ignored fourth'),
    ]);
    expect(
      HomeDoorCatalog.instance.discoveries.map((tool) => tool.routeName),
      ['/screen138', '/screen80', '/screen87'],
    );
    expect(
      HomeDoorCatalog.instance.destinations.map((tool) => tool.routeName).toSet().length,
      HomeDoorCatalog.instance.destinations.length,
    );
    HomeDoorCatalog.instance.clearDiscoveries();
    expect(HomeDoorCatalog.instance.destinations.map((tool) => tool.routeName),
        appTools.map((tool) => tool.routeName));
  });

  testWidgets('Door follows refreshed Home selections and navigates selected screen',
      (tester) async {
    await tester.pumpWidget(
      await wrapWithDisplayScope(
        MaterialApp(
          initialRoute: RouteNames.photoStudio,
          routes: {
            RouteNames.photoStudio: (_) => const Scaffold(
                  body: ToolDoorSelector(currentRouteName: RouteNames.photoStudio),
                ),
            '/screen80': (_) => const Scaffold(body: Text('dynamic-screen-80')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<String?> values() =>
        [for (final item in _dropdown(tester).items!) item.value];

    expect(values(), containsAll([RouteNames.hub, RouteNames.uiShowcase, RouteNames.externalMcp]));
    expect(values(), isNot(contains('/screen138')));

    HomeDoorCatalog.instance.updateDiscoveries(const [
      AppTool(routeName: '/screen138', label: 'Screen138 · old draw'),
    ]);
    await tester.pump();
    expect(values(), contains('/screen138'));

    HomeDoorCatalog.instance.updateDiscoveries(const [
      AppTool(routeName: '/screen80', label: 'Screen80 · current draw'),
    ]);
    await tester.pump();
    expect(values(), contains('/screen80'));
    expect(values(), isNot(contains('/screen138')));

    // Exercise the menu and Navigator, not just its onChanged callback.
    await tester.tap(_doorDropdown());
    await tester.pumpAndSettle();
    expect(find.text('Screen138 · old draw'), findsNothing);
    // The dropdown initially scrolls around the current tool. Featured items
    // above it can be unbuilt; scroll the popup rather than ensureVisible on
    // an element that does not exist yet.
    final destination = find.text('Screen80 · current draw');
    await tester.scrollUntilVisible(
      destination,
      -80,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 20,
    );
    await tester.tap(destination.last);
    await tester.pumpAndSettle();
    expect(find.text('dynamic-screen-80'), findsOneWidget);
  });

  testWidgets('a deep linked numbered page remains marked current after Home refresh',
      (tester) async {
    HomeDoorCatalog.instance.updateDiscoveries(const [
      AppTool(routeName: '/screen80', label: 'Screen80 · featured'),
    ]);
    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(
          home: Scaffold(
            body: ToolDoorSelector(currentRouteName: '/screen138'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dropdown = _dropdown(tester);
    expect(dropdown.items!.map((item) => item.value),
        containsAll(['/screen80', '/screen138']));
    expect(dropdown.items!.firstWhere((item) => item.value == '/screen138').enabled, isFalse);
    expect(find.textContaining('Screen138'), findsWidgets);
  });

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
