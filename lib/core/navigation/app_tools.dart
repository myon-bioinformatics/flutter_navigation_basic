import 'package:flutter/material.dart';

import 'route_names.dart';

/// One route/label identity for Home navigation and the Door-to-Door footer.
/// The optional Home metadata is only used by cards shown on Home.
class AppTool {
  const AppTool({
    required this.routeName,
    this.labelKey,
    this.label,
    this.homeLabelKey,
    this.homeSubtitleKey,
    this.homeIcon,
  }) : assert(labelKey != null || label != null);

  final String routeName;
  final String? labelKey;
  /// Captured Home discovery title. Unlike a translation key, it comes from
  /// the exact screen metadata displayed when the Home draw was selected.
  final String? label;
  final String? homeLabelKey;
  final String? homeSubtitleKey;
  final IconData? homeIcon;
}

/// The fixed Home cards are the single source for stable Home destinations.
/// Do not duplicate route names in HomeScreen and the footer.
const List<AppTool> homeAppTools = [
  AppTool(
    routeName: RouteNames.clipboardShelf,
    labelKey: 'clipboardShelf.appBarTitle',
    homeLabelKey: 'home.action.clipboardShelfProd.label',
    homeSubtitleKey: 'home.action.clipboardShelfProd.subtitle',
    homeIcon: Icons.inventory_2_outlined,
  ),
  AppTool(
    routeName: RouteNames.nowTimeline,
    labelKey: 'nowTimeline.title',
    homeSubtitleKey: 'home.action.nowTimeline.subtitle',
    homeIcon: Icons.public_outlined,
  ),
  AppTool(
    routeName: RouteNames.coordinateTool,
    labelKey: 'coordinate.title',
    homeSubtitleKey: 'home.action.coordinateTool.subtitle',
    homeIcon: Icons.my_location_outlined,
  ),
  AppTool(
    routeName: RouteNames.photoStudio,
    labelKey: 'photoStudio.title',
    homeSubtitleKey: 'home.action.photoStudio.subtitle',
    homeIcon: Icons.photo_outlined,
  ),
  AppTool(
    routeName: RouteNames.httpRequestDraft,
    labelKey: 'httpDraft.title',
    homeSubtitleKey: 'home.action.httpRequestDraft.subtitle',
    homeIcon: Icons.http_outlined,
  ),
  AppTool(
    routeName: RouteNames.hub,
    labelKey: 'home.action.hub.label',
    homeSubtitleKey: 'home.action.hub.subtitle',
    homeIcon: Icons.map_outlined,
  ),
  AppTool(
    routeName: RouteNames.uiShowcase,
    labelKey: 'home.action.uiShowcase.label',
    homeSubtitleKey: 'home.action.uiShowcase.subtitle',
    homeIcon: Icons.dashboard_customize_outlined,
  ),
  AppTool(
    routeName: RouteNames.externalMcp,
    labelKey: 'home.action.mcpIntegration.label',
    homeSubtitleKey: 'home.action.mcpIntegration.subtitle',
    homeIcon: Icons.hub_outlined,
  ),
  AppTool(
    routeName: RouteNames.counterPlayground,
    labelKey: 'nav.counterPlayground',
    homeLabelKey: 'home.action.counterPlaygroundProd.label',
    homeSubtitleKey: 'home.action.counterPlaygroundProd.subtitle',
    homeIcon: Icons.exposure_plus_1_outlined,
  ),
  AppTool(
    routeName: RouteNames.ironyGenerator,
    labelKey: 'nav.ironyGenerator',
    homeLabelKey: 'home.action.ironyGeneratorProd.label',
    homeSubtitleKey: 'home.action.ironyGeneratorProd.subtitle',
    homeIcon: Icons.auto_awesome_outlined,
  ),
  AppTool(
    routeName: RouteNames.compositionGenerator,
    labelKey: 'compositionGenerator.title',
    homeLabelKey: 'home.action.compositionStudio.label',
    homeSubtitleKey: 'home.action.compositionStudio.subtitle',
    homeIcon: Icons.music_note_outlined,
  ),
];

/// Stable footer destinations; valid even when Home discovery data is absent.
List<AppTool> get appTools => const [
      AppTool(routeName: RouteNames.home, labelKey: 'home.title'),
      ...homeAppTools,
      // Stable legacy tool is still reachable even though it is not a Home card.
      AppTool(routeName: RouteNames.screen5, labelKey: 'urlParameters.title'),
    ];

/// Last *actually rendered* Home discoveries, not a second random draw.
///
/// Home publishes its current selection after successful loading/refresh.
/// Other pages read that session snapshot; a direct cold deep link sees only
/// stable destinations. No persistence and no background asset read is needed.
class HomeDoorCatalog extends ChangeNotifier {
  HomeDoorCatalog._();

  static final HomeDoorCatalog instance = HomeDoorCatalog._();

  List<AppTool> _discoveries = const [];
  List<AppTool> get discoveries => List.unmodifiable(_discoveries);
  List<AppTool> get destinations => List.unmodifiable([
        ...appTools,
        ..._discoveries,
      ]);

  void updateDiscoveries(Iterable<AppTool> proposed) {
    final seen = appTools.map((tool) => tool.routeName).toSet();
    final accepted = <AppTool>[];
    for (final tool in proposed) {
      const prefix = '/screen';
      if (!tool.routeName.startsWith(prefix)) continue;
      final id = int.tryParse(tool.routeName.substring(prefix.length));
      if (id == null || id < 6 || id > 198) continue;
      if (tool.label == null || tool.label!.trim().isEmpty) continue;
      if (!seen.add(tool.routeName)) continue;
      accepted.add(tool);
      if (accepted.length == 3) break;
    }
    _discoveries = List.unmodifiable(accepted);
    notifyListeners();
  }

  void clearDiscoveries() => updateDiscoveries(const []);
}
