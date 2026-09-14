import 'package:flutter/material.dart';

import '../../features/clipboard_shelf/presentation/clipboard_shelf_page.dart';
import '../../features/clipboard_workbench/presentation/clipboard_workbench_page.dart';
import '../../features/coordinate_tool/presentation/coordinate_tool_page.dart';
import '../../features/home/domain/home_controller.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/http_request_draft/presentation/http_request_draft_page.dart';
import '../../features/now_timeline/presentation/now_timeline_page.dart';
import '../../features/photo_studio/presentation/photo_studio_page.dart';
import '../../features/screen5/domain/screen5_controller.dart';
import '../../features/screen5/presentation/screen5_page.dart';
import 'route_names.dart';
import '../../screens/composition_studio_screen.dart';
import '../../screens/counter_playground_screen.dart';
import '../../screens/hub_screen.dart';
import '../../screens/irony_generator_screen.dart';
import '../../screens/mcp_integration_screen.dart';
import '../../screens/mock_api_screen.dart';
import '../../screens/ui_showcase_screen.dart';

/// Single source of route name → page builder metadata for both entrypoints.
///
/// `main.dart` ([AppRoutes]) and `main_prod.dart` ([AppNavigation]) must mount
/// these same builders so GitHub Pages (default `main.dart`) and prod CI smoke
/// show the same Door-enabled feature pages.
class AppRouteRegistry {
  AppRouteRegistry._();

  /// Canonical tool routes (Door catalogue) plus legacy deep-link aliases.

  /// Public catalogue / integration routes shared by both entrypoints.
  static Map<String, WidgetBuilder> get catalogueRoutes => {
        '/hub': (_) => const HubScreen(),
        '/examples/ui-showcase': (_) => const UiShowcaseScreen(),
        '/examples/external-integration/api': (_) => const ApiIntegrationScreen(),
        '/examples/external-integration/mcp': (_) => const McpIntegrationScreen(),
      };

  static Map<String, WidgetBuilder> get canonicalRoutes => {
        RouteNames.home: (_) => HomeScreen(controller: HomeController()),
        RouteNames.clipboardShelf: (_) => const ClipboardShelfPage(),
        RouteNames.nowTimeline: (_) => const NowTimelinePage(),
        RouteNames.coordinateTool: (_) => const CoordinateToolPage(),
        RouteNames.photoStudio: (_) => const PhotoStudioPage(),
        RouteNames.boundingBox: (_) => const PhotoStudioPage(),
        // Stateful wrappers own a single controller instance for the route
        // lifetime (avoid recreating controllers on StatelessWidget rebuilds).
        RouteNames.counterPlayground: (_) => const CounterPlaygroundScreen(),
        RouteNames.ironyGenerator: (_) => const IronyGeneratorScreen(),
        RouteNames.compositionGenerator: (_) => const CompositionStudioScreen(),
        RouteNames.compositionSeedGenerator: (_) =>
            const CompositionStudioScreen(),
        RouteNames.clipboardWorkbench: (_) => const ClipboardWorkbenchPage(),
        RouteNames.httpRequestDraft: (_) => const HttpRequestDraftPage(),
        RouteNames.screen5: (_) => Screen5Page(controller: Screen5Controller()),
      };
}
