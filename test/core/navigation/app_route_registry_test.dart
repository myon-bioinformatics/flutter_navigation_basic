import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/core/navigation/app_navigation.dart';
import 'package:flutter_application_1/core/navigation/app_route_registry.dart';
import 'package:flutter_application_1/core/navigation/app_tools.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/features/composition_generator/presentation/composition_generator_page.dart';
import 'package:flutter_application_1/features/counter_playground/presentation/counter_playground_page.dart';
import 'package:flutter_application_1/features/http_request_draft/presentation/http_request_draft_page.dart';
import 'package:flutter_application_1/features/now_timeline/presentation/time_rules_bootstrap.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_application_1/screens/counter_playground_screen.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/display_test_harness.dart';

Future<void> _pumpNamedRoute(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> routes,
  required String initialRoute,
  Size surface = const Size(390, 2400),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  if (initialRoute == AppRoutes.uiShowcase) {
    // Start AND finish asset loading/UTF-8 decoding in real async time.
    // Pumping after a cached future was created in another fake-time test
    // cannot guarantee that its isolate/IO callbacks will ever complete.
    await tester.runAsync(() async {
      const asset = 'assets/ui_showcase.json';
      rootBundle.evict(asset);
      await rootBundle.loadString(asset).timeout(const Duration(seconds: 10));
    });
  }

  await tester.pumpWidget(
    await wrapWithDisplayScope(
      MediaQuery(
        data: MediaQueryData(size: surface),
        child: MaterialApp(
          initialRoute: initialRoute,
          routes: routes,
        ),
      ),
    ),
  );
  // Like the existing Hub harness, let real asset IO (e.g. UI Showcase's
  // config) complete outside fake time before settling Flutter animations.
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }
  expect(find.byType(CircularProgressIndicator), findsNothing,
      reason: '$initialRoute must finish loading before checking its chrome');
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(loadTimeRules);
  setUp(() {
    // Route/chrome tests should not wait on real asset IO under fake time.
    // Exercise the real Hub builder with a nonempty deterministic catalogue.
    ScreensConfig.resetCache(loader: () async => const [
      ScreenData(
        screenDataId: 6, name: 'Screen6', title: 'Route fixture', emoji: '🌍',
        description: 'Deterministic route test catalogue', category: 'navigation',
        navigationPattern: '', apiPattern: '', themePattern: '', dataPattern: '',
      ),
    ]);
    HomeDoorCatalog.instance.clearDiscoveries();
  });
  tearDown(() {
    ScreensConfig.resetCache();
    HomeDoorCatalog.instance.clearDiscoveries();
  });

  test('AppNavigation and AppRoutes share canonical + catalogue route keys', () {
    final canonical = AppRouteRegistry.canonicalRoutes.keys.toSet();
    final catalogue = AppRouteRegistry.catalogueRoutes.keys.toSet();
    final prod = AppNavigation.routes.keys.toSet();
    final public = AppRoutes.routes.keys.toSet();

    expect(prod.containsAll(canonical), isTrue);
    expect(prod.containsAll(catalogue), isTrue);
    expect(public.containsAll(canonical), isTrue);
    expect(public.containsAll(catalogue), isTrue);
  });

  test('public route table resolves the canonical Photo Studio route', () {
    expect(RouteNames.photoStudio, '/tools/media/photo-studio');
    expect(AppRoutes.routes.containsKey(RouteNames.photoStudio), isTrue);
  });

  testWidgets('legacy API routes land on the consolidated HTTP Request Draft',
      (tester) async {
    for (final route in [AppRoutes.externalApi, AppRoutes.mockApi]) {
      await _pumpNamedRoute(
        tester,
        routes: AppRoutes.routes,
        initialRoute: route,
      );
      expect(find.byType(HttpRequestDraftPage), findsOneWidget);
    }
  });

  testWidgets('public Photo Studio route lands on PhotoStudioPage',
      (tester) async {
    await _pumpNamedRoute(
      tester,
      routes: AppRoutes.routes,
      initialRoute: RouteNames.photoStudio,
    );
    expect(find.byType(PhotoStudioPage), findsOneWidget);
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

  testWidgets('catalogue screen builders capture distinct screen ids',
      (tester) async {
    Future<void> expectScreenId(int id) async {
      await tester.pumpWidget(
        await wrapWithDisplayScope(
          MaterialApp(
            home: Builder(
              builder: (context) =>
                  AppRoutes.routes[AppRoutes.screenRoute(id)]!(context),
            ),
          ),
        ),
      );
      await tester.pump();
      final screen = tester.widget<GenericScreen>(find.byType(GenericScreen));
      expect(screen.screenId, id);
    }

    await expectScreenId(1);
    await expectScreenId(42);
    await expectScreenId(198);
  });

  testWidgets('CounterPlaygroundScreen keeps controller across parent rebuild',
      (tester) async {
    Future<void> pumpWithWidth(double width) async {
      await tester.pumpWidget(
        await wrapWithDisplayScope(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: const CounterPlaygroundScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWithWidth(390);
    final page = tester.widget<CounterPlaygroundPage>(
      find.byType(CounterPlaygroundPage),
    );
    final controller = page.controller;
    controller.increment();
    expect(controller.counter, 1);

    await pumpWithWidth(320);
    final rebuilt = tester.widget<CounterPlaygroundPage>(
      find.byType(CounterPlaygroundPage),
    );
    expect(identical(rebuilt.controller, controller), isTrue);
    expect(rebuilt.controller.counter, 1);
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

  group('narrow phone surfaces without RenderFlex overflow', () {
    const surfaces = <Size>[
      Size(390, 2400),
      Size(320, 2400),
    ];

    for (final surface in surfaces) {
      for (final route in [
        RouteNames.home,
        RouteNames.coordinateTool,
        RouteNames.compositionGenerator,
        RouteNames.ironyGenerator,
        RouteNames.counterPlayground,
        RouteNames.hub,
        RouteNames.uiShowcase,
        RouteNames.externalMcp,
      ]) {
        testWidgets(
            'public $route at ${surface.width.toInt()}px has no overflow',
            (tester) async {
          await _pumpNamedRoute(
            tester,
            routes: AppRoutes.routes,
            initialRoute: route,
            surface: surface,
          );
        });
      }
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
