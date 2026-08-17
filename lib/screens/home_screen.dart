import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../shared/display/display_scope.dart';
import '../shared/widgets/home_overview_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime get nowadays => DateTime.now();

  String get today {
    final value = nowadays;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('home.title')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [DisplayLocalePicker(compact: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(today, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                HomeOverviewPanel(
                  actions: [
                    HomeOverviewAction(label: t('home.clipboardShelf'), subtitle: t('home.clipboardShelfSubtitle'), icon: Icons.inventory_2_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardShelf)),
                    HomeOverviewAction(label: t('home.nowTimeline'), subtitle: t('home.nowTimelineSubtitle'), icon: Icons.public_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.nowTimeline)),
                    HomeOverviewAction(label: t('home.coordinates'), subtitle: t('home.coordinatesSubtitle'), icon: Icons.my_location_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.coordinateTool)),
                    HomeOverviewAction(label: t('home.workbench'), subtitle: t('home.workbenchSubtitle'), icon: Icons.content_paste_go_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardWorkbench)),
                    HomeOverviewAction(label: t('home.navigationHub'), subtitle: t('home.navigationHubSubtitle'), icon: Icons.map_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.hub)),
                    HomeOverviewAction(label: t('home.uiShowcase'), subtitle: t('home.uiShowcaseSubtitle'), icon: Icons.dashboard_customize_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.uiShowcase)),
                    HomeOverviewAction(label: t('home.api'), subtitle: t('home.apiSubtitle'), icon: Icons.http_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.externalApi)),
                    HomeOverviewAction(label: t('home.mcp'), subtitle: t('home.mcpSubtitle'), icon: Icons.hub_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.externalMcp)),
                    HomeOverviewAction(label: t('home.counter'), subtitle: t('home.counterSubtitle'), icon: Icons.exposure_plus_1_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.counterPlayground)),
                    HomeOverviewAction(label: t('home.irony'), subtitle: t('home.ironySubtitle'), icon: Icons.auto_awesome_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.ironyGenerator)),
                    HomeOverviewAction(label: t('home.composition'), subtitle: t('home.compositionSubtitle'), icon: Icons.music_note_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.compositionGenerator)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
