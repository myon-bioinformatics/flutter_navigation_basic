import 'package:flutter/material.dart';

import '../core/navigation/app_route_registry.dart';
import '../core/navigation/route_names.dart';
import '../screens/generic_screen.dart';
import '../screens/mock_api_screen.dart';

/// Public (`main.dart`) route table.
///
/// Tool routes come from [AppRouteRegistry] so GitHub Pages shows the same
/// Door-enabled feature pages as `main_prod.dart` / [AppNavigation].
class AppRoutes {
  static const String home = RouteNames.home;
  static const String hub = '/hub';

  static const String clipboardShelf = RouteNames.clipboardShelf;
  static const String nowTimeline = RouteNames.nowTimeline;
  static const String coordinateTool = RouteNames.coordinateTool;
  static const String photoStudio = RouteNames.photoStudio;
  static const String boundingBox = RouteNames.boundingBox;
  static const String counterPlayground = RouteNames.counterPlayground;
  static const String ironyGenerator = RouteNames.ironyGenerator;
  static const String compositionGenerator = RouteNames.compositionGenerator;
  static const String compositionSeedGenerator =
      RouteNames.compositionSeedGenerator;
  static const String clipboardWorkbench = RouteNames.clipboardWorkbench;
  static const String httpRequestDraft = RouteNames.httpRequestDraft;
  static const String uiShowcase = '/examples/ui-showcase';

  static const String externalApi = '/examples/external-integration/api';
  static const String externalMcp = '/examples/external-integration/mcp';
  static const String mockApi = '/examples/mock-api';

  static String screenRoute(int id) => '/screen$id';

  static final Map<String, WidgetBuilder> routes = _buildRoutes();

  static Map<String, WidgetBuilder> _buildRoutes() {
    final map = <String, WidgetBuilder>{
      ...AppRouteRegistry.canonicalRoutes,
    };

    // Catalogue / demo routes that are public-entrypoint only.
    for (var i = 1; i <= 198; i++) {
      // Capture per-iteration so each builder closes over a fixed screen id.
      final screenId = i;
      final name = screenRoute(screenId);
      map.putIfAbsent(
        name,
        () => (_) => GenericScreen(screenId: screenId),
      );
    }

    map.addAll(AppRouteRegistry.catalogueRoutes);
    map[mockApi] = (_) => const ApiIntegrationScreen();

    return map;
  }
}
