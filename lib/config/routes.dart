import 'package:flutter/material.dart';

import '../core/navigation/app_route_registry.dart';
import '../core/data_processing/native_parallel_pattern_example.dart';
import '../core/data_processing/interactive_pattern_example.dart';
import '../core/navigation/route_names.dart';
import '../screens/generic_screen.dart';

/// Public (`main.dart`) route table.
///
/// Tool routes come from [AppRouteRegistry] for the canonical Web/native app.
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

    // Real native interactions are available on their numbered catalogue routes.
    // Keep the E2E aliases for existing browser test compatibility.
    {
      for (final patternId in [171, 172, 173, 174, 175, 183, 184]) {
        map[screenRoute(patternId)] =
            (_) => InteractivePatternExample(patternId: patternId);
        if (const bool.fromEnvironment('E2E', defaultValue: false)) {
          map['/examples/data-processing-interactions/$patternId'] =
              map[screenRoute(patternId)]!;
        }
      }
    }

    for (final id in [136, 137]) {
      map[screenRoute(id)] =
          (_) => NativeParallelPatternExample(patternId: id);
    }

    map.addAll(AppRouteRegistry.catalogueRoutes);
    map[mockApi] = AppRouteRegistry.canonicalRoutes[RouteNames.httpRequestDraft]!;

    return map;
  }
}
