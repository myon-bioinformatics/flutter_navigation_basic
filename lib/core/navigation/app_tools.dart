import 'app_navigation.dart';
import 'route_names.dart';

/// Metadata for Door-to-Door tool switching (production routes).
class AppTool {
  const AppTool({
    required this.routeName,
    required this.labelKey,
    required this.navigate,
  });

  final String routeName;
  final String labelKey;
  final void Function() navigate;
}

/// Canonical tool list for the shared footer selector.
///
/// Home is included so users can leave a tool without the system back stack.
List<AppTool> get appTools => [
      AppTool(
        routeName: RouteNames.home,
        labelKey: 'home.title',
        navigate: AppNavigation.toHome,
      ),
      AppTool(
        routeName: RouteNames.clipboardShelf,
        labelKey: 'clipboardShelf.appBarTitle',
        navigate: AppNavigation.toClipboardShelf,
      ),
      AppTool(
        routeName: RouteNames.nowTimeline,
        labelKey: 'nowTimeline.title',
        navigate: AppNavigation.toNowTimeline,
      ),
      AppTool(
        routeName: RouteNames.coordinateTool,
        labelKey: 'coordinate.title',
        navigate: AppNavigation.toCoordinateTool,
      ),
      AppTool(
        routeName: RouteNames.photoStudio,
        labelKey: 'photoStudio.title',
        navigate: AppNavigation.toPhotoStudio,
      ),
      AppTool(
        routeName: RouteNames.clipboardWorkbench,
        labelKey: 'clipboardWorkbench.appBarTitle',
        navigate: AppNavigation.toClipboardWorkbench,
      ),
      AppTool(
        routeName: RouteNames.counterPlayground,
        labelKey: 'nav.counterPlayground',
        navigate: AppNavigation.toCounterPlayground,
      ),
      AppTool(
        routeName: RouteNames.ironyGenerator,
        labelKey: 'nav.ironyGenerator',
        navigate: AppNavigation.toIronyGenerator,
      ),
      AppTool(
        routeName: RouteNames.compositionGenerator,
        labelKey: 'compositionGenerator.title',
        navigate: AppNavigation.toCompositionGenerator,
      ),
      AppTool(
        routeName: RouteNames.screen5,
        labelKey: 'urlParameters.title',
        navigate: AppNavigation.toScreen5,
      ),
    ];
