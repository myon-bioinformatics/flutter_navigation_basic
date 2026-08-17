import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/domain/home_controller.dart';
import '../../features/clipboard_shelf/presentation/clipboard_shelf_page.dart';
import '../../features/now_timeline/presentation/now_timeline_page.dart';
import '../../features/coordinate_tool/presentation/coordinate_tool_page.dart';
import '../../features/counter_playground/presentation/counter_playground_page.dart';
import '../../features/counter_playground/domain/counter_playground_controller.dart';
import '../../features/irony_generator/presentation/irony_generator_page.dart';
import '../../features/irony_generator/domain/irony_generator_controller.dart';
import '../../features/composition_generator/presentation/composition_generator_page.dart';
import '../../features/composition_generator/domain/composition_generator_controller.dart';
import '../../features/clipboard_workbench/presentation/clipboard_workbench_page.dart';
import '../../features/screen5/presentation/screen5_page.dart';
import '../../features/screen5/domain/screen5_controller.dart';

class AppNavigation {
  AppNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('AppNavigation.navigatorKey is not attached to a Navigator.');
    }
    return state;
  }

  static Map<String, WidgetBuilder> get routes => {
        RouteNames.home: (_) => HomeScreen(controller: HomeController()),
        RouteNames.clipboardShelf: (_) => const ClipboardShelfPage(),
        RouteNames.nowTimeline: (_) => const NowTimelinePage(),
        RouteNames.coordinateTool: (_) => const CoordinateToolPage(),
        RouteNames.counterPlayground: (_) => CounterPlaygroundPage(
              controller: CounterPlaygroundController(),
            ),
        RouteNames.ironyGenerator: (_) => IronyGeneratorPage(
              controller: IronyGeneratorController(),
            ),
        RouteNames.compositionGenerator: (_) => CompositionGeneratorPage(
              controller: CompositionGeneratorController(),
            ),
        RouteNames.clipboardWorkbench: (_) => const ClipboardWorkbenchPage(),
        RouteNames.screen5: (_) => Screen5Page(controller: Screen5Controller()),
      };

  static void toHome() => _navigator.pushNamedAndRemoveUntil(
        RouteNames.home,
        (route) => false,
      );
  static void toClipboardShelf() => _navigator.pushNamed(RouteNames.clipboardShelf);
  static void toNowTimeline() => _navigator.pushNamed(RouteNames.nowTimeline);
  static void toCoordinateTool() => _navigator.pushNamed(RouteNames.coordinateTool);
  static void toCounterPlayground() =>
      _navigator.pushNamed(RouteNames.counterPlayground);
  static void toIronyGenerator() => _navigator.pushNamed(RouteNames.ironyGenerator);
  static void toCompositionGenerator() =>
      _navigator.pushNamed(RouteNames.compositionGenerator);
  static void toClipboardWorkbench() =>
      _navigator.pushNamed(RouteNames.clipboardWorkbench);
  static void toScreen5() => _navigator.pushNamed(RouteNames.screen5);
  static void back() => _navigator.maybePop();
}
