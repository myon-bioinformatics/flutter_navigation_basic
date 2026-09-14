import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/core/navigation/app_navigation.dart';
import 'package:flutter_application_1/core/navigation/app_route_registry.dart';
import 'package:flutter_application_1/core/navigation/app_tools.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/features/composition_generator/presentation/composition_generator_page.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/display_test_harness.dart';

void _ignoreLayoutOverflowErrors(WidgetTester tester) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = previous;
  });
}

Future<void> _pumpNamedRoute(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> routes,
  required String initialRoute,
}) async {
  _ignoreLayoutOverflowErrors(tester);

  // Photo Studio / Composition need a tall surface so Door is on-stage.
  const surface = Size(1100, 2400);
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    await wrapWithDisplayScope(
      MaterialApp(
        initialRoute: initialRoute,
        routes: routes,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppNavigation and AppRoutes share the same canonical route keys', () {
    final canonical = AppRouteRegistry.canonicalRoutes.keys.toSet();
    final prod = AppNavigation.routes.keys.toSet();
    final public = AppRoutes.routes.keys.toSet();

    expect(prod, equals(canonical));
    expect(public.containsAll(canonical), isTrue);
  });

  test('legacy deep-link aliases stay in the shared registry', () {
    final canonical = AppRouteRegistry.canonicalRoutes;
    expect(canonical.containsKey(RouteNames.boundingBox), isTrue);
    expect(canonical.containsKey(RouteNames.compositionSeedGenerator), isTrue);
    expect(
      RouteNames.compositionSeedGenerator,
      '/examples/composition-generator/seed',
    );
  });

  testWidgets('public AppRoutes boundingBox alias lands on PhotoStudioPage',
      (tester) async {
    await _pumpNamedRoute(
      tester,
      routes: AppRoutes.routes,
      initialRoute: RouteNames.boundingBox,
    );
    expect(find.byType(PhotoStudioPage), findsOneWidget);
  });

  testWidgets(
      'public AppRoutes composition seed alias lands on CompositionGeneratorPage',
      (tester) async {
    await _pumpNamedRoute(
      tester,
      routes: AppRoutes.routes,
      initialRoute: RouteNames.compositionSeedGenerator,
    );
    expect(find.byType(CompositionGeneratorPage), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
  });

  testWidgets('prod AppNavigation boundingBox alias lands on PhotoStudioPage',
      (tester) async {
    await _pumpNamedRoute(
      tester,
      routes: AppNavigation.routes,
      initialRoute: RouteNames.boundingBox,
    );
    expect(find.byType(PhotoStudioPage), findsOneWidget);
  });

  testWidgets(
      'prod AppNavigation composition seed alias lands on CompositionGeneratorPage',
      (tester) async {
    await _pumpNamedRoute(
      tester,
      routes: AppNavigation.routes,
      initialRoute: RouteNames.compositionSeedGenerator,
    );
    expect(find.byType(CompositionGeneratorPage), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
  });

  group('Door presence on appTools routes (public AppRoutes)', () {
    for (final tool in appTools) {
      if (tool.routeName == RouteNames.home) {
        // Home is a Door destination; it does not host a Door itself.
        continue;
      }

      testWidgets('${tool.routeName} shows exactly one ToolDoorSelector',
          (tester) async {
        await _pumpNamedRoute(
          tester,
          routes: AppRoutes.routes,
          initialRoute: tool.routeName,
        );
        expect(find.byType(ToolDoorSelector), findsOneWidget);
      });
    }
  });

  group('Door presence on appTools routes (prod AppNavigation)', () {
    for (final tool in appTools) {
      if (tool.routeName == RouteNames.home) {
        continue;
      }

      testWidgets('${tool.routeName} shows exactly one ToolDoorSelector',
          (tester) async {
        await _pumpNamedRoute(
          tester,
          routes: AppNavigation.routes,
          initialRoute: tool.routeName,
        );
        expect(find.byType(ToolDoorSelector), findsOneWidget);
      });
    }
  });

  testWidgets(
      'public path former screen farm tools expose Door without NavButton farm',
      (tester) async {
    const formerFarms = [
      RouteNames.clipboardShelf,
      RouteNames.clipboardWorkbench,
      RouteNames.counterPlayground,
      RouteNames.ironyGenerator,
      RouteNames.compositionGenerator,
    ];

    for (final route in formerFarms) {
      await _pumpNamedRoute(
        tester,
        routes: AppRoutes.routes,
        initialRoute: route,
      );
      expect(
        find.byType(ToolDoorSelector),
        findsOneWidget,
        reason: '$route must show Door on public AppRoutes',
      );
    }
  });
}
