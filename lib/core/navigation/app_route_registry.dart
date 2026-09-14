import 'package:flutter/material.dart';

import '../../features/clipboard_shelf/presentation/clipboard_shelf_page.dart';
import '../../features/clipboard_workbench/presentation/clipboard_workbench_page.dart';
import '../../features/composition_generator/domain/composition_generator_controller.dart';
import '../../features/composition_generator/presentation/composition_generator_page.dart';
import '../../features/coordinate_tool/presentation/coordinate_tool_page.dart';
import '../../features/counter_playground/domain/counter_playground_controller.dart';
import '../../features/counter_playground/presentation/counter_playground_page.dart';
import '../../features/home/domain/home_controller.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/irony_generator/domain/irony_generator_controller.dart';
import '../../features/irony_generator/presentation/irony_generator_page.dart';
import '../../features/now_timeline/presentation/now_timeline_page.dart';
import '../../features/photo_studio/presentation/photo_studio_page.dart';
import '../../features/screen5/domain/screen5_controller.dart';
import '../../features/screen5/presentation/screen5_page.dart';
import 'route_names.dart';

/// Single source of route name → page builder metadata for both entrypoints.
///
/// `main.dart` ([AppRoutes]) and `main_prod.dart` ([AppNavigation]) must mount
/// these same builders so GitHub Pages (default `main.dart`) and prod CI smoke
/// show the same Door-enabled feature pages.
class AppRouteRegistry {
  AppRouteRegistry._();

  /// Canonical tool routes (Door catalogue) plus legacy deep-link aliases.
  static Map<String, WidgetBuilder> get canonicalRoutes => {
        RouteNames.home: (_) => HomeScreen(controller: HomeController()),
        RouteNames.clipboardShelf: (_) => const ClipboardShelfPage(),
        RouteNames.nowTimeline: (_) => const NowTimelinePage(),
        RouteNames.coordinateTool: (_) => const CoordinateToolPage(),
        RouteNames.photoStudio: (_) => const PhotoStudioPage(),
        RouteNames.boundingBox: (_) => const PhotoStudioPage(),
        RouteNames.counterPlayground: (_) => CounterPlaygroundPage(
              controller: CounterPlaygroundController(),
            ),
        RouteNames.ironyGenerator: (_) => IronyGeneratorPage(
              controller: IronyGeneratorController(),
            ),
        RouteNames.compositionGenerator: (_) => CompositionGeneratorPage(
              controller: CompositionGeneratorController(),
            ),
        RouteNames.compositionSeedGenerator: (_) => CompositionGeneratorPage(
              controller: CompositionGeneratorController(),
            ),
        RouteNames.clipboardWorkbench: (_) => const ClipboardWorkbenchPage(),
        RouteNames.screen5: (_) => Screen5Page(controller: Screen5Controller()),
      };
}
