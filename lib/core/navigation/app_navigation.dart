import 'package:flutter/material.dart';

import 'app_route_registry.dart';
import 'route_names.dart';

class AppNavigation {
  AppNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'AppNavigation.navigatorKey is not attached to a Navigator.',
      );
    }
    return state;
  }

  /// Same canonical builders as [AppRoutes] / public `main.dart`.
  static Map<String, WidgetBuilder> get routes => {
        ...AppRouteRegistry.canonicalRoutes,
        ...AppRouteRegistry.catalogueRoutes,
      };

  static void toHome() => _navigator.pushNamedAndRemoveUntil(
        RouteNames.home,
        (route) => false,
      );
  static void toClipboardShelf() =>
      _navigator.pushNamed(RouteNames.clipboardShelf);
  static void toNowTimeline() => _navigator.pushNamed(RouteNames.nowTimeline);
  static void toCoordinateTool() =>
      _navigator.pushNamed(RouteNames.coordinateTool);
  static void toPhotoStudio() => _navigator.pushNamed(RouteNames.photoStudio);
  static void toBoundingBox() => _navigator.pushNamed(RouteNames.photoStudio);
  static void toCounterPlayground() =>
      _navigator.pushNamed(RouteNames.counterPlayground);
  static void toIronyGenerator() =>
      _navigator.pushNamed(RouteNames.ironyGenerator);
  static void toCompositionGenerator() =>
      _navigator.pushNamed(RouteNames.compositionGenerator);
  static void toClipboardWorkbench() =>
      _navigator.pushNamed(RouteNames.clipboardWorkbench);
  static void toScreen5() => _navigator.pushNamed(RouteNames.screen5);
  static void back() => _navigator.maybePop();
}
