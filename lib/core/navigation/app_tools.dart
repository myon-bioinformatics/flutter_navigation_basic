import 'route_names.dart';

/// Metadata for Door-to-Door tool switching (production routes).
///
/// Navigation is performed by [ToolDoorSelector] through [Navigator.of] so
/// both `main.dart` ([AppRoutes]) and `main_prod.dart` ([AppNavigation])
/// entrypoints work without relying on [AppNavigation.navigatorKey].
class AppTool {
  const AppTool({
    required this.routeName,
    required this.labelKey,
  });

  final String routeName;
  final String labelKey;
}

/// Canonical tool list for the shared footer selector.
///
/// Home is included so users can leave a tool without the system back stack.
List<AppTool> get appTools => const [
      AppTool(
        routeName: RouteNames.home,
        labelKey: 'home.title',
      ),
      AppTool(
        routeName: RouteNames.clipboardShelf,
        labelKey: 'clipboardShelf.appBarTitle',
      ),
      AppTool(
        routeName: RouteNames.nowTimeline,
        labelKey: 'nowTimeline.title',
      ),
      AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
      ),
      AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
      ),
      AppTool(
        routeName: RouteNames.clipboardWorkbench,
        labelKey: 'clipboardWorkbench.appBarTitle',
      ),
      AppTool(
        routeName: RouteNames.httpRequestDraft,
        labelKey: 'httpDraft.title',
      ),
      AppTool(
        routeName: RouteNames.counterPlayground,
        labelKey: 'nav.counterPlayground',
      ),
      AppTool(
        routeName: RouteNames.ironyGenerator,
        labelKey: 'nav.ironyGenerator',
      ),
      AppTool(
        routeName: RouteNames.compositionGenerator,
        labelKey: 'compositionGenerator.title',
      ),
      AppTool(
        routeName: RouteNames.screen5,
        labelKey: 'urlParameters.title',
      ),
    ];
