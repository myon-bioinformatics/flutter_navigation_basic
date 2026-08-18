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

  String _today(DisplayController display) {
    final weekdays = <String>[
      display.text('common.weekday.mon'),
      display.text('common.weekday.tue'),
      display.text('common.weekday.wed'),
      display.text('common.weekday.thu'),
      display.text('common.weekday.fri'),
      display.text('common.weekday.sat'),
      display.text('common.weekday.sun'),
    ];
    final value = nowadays;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final weekday = weekdays[value.weekday - 1];
    return '${value.year}/$month/$day($weekday)';
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('home.title')),
        actions: [
          IconButton(
            tooltip: display.text('common.refresh'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const DisplayLocalePicker(compact: true),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_today(display), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                HomeOverviewPanel(
                  title: display.text('homeOverview.title'),
                  subtitle: display.text('homeOverview.subtitle'),
                  actions: [
                    HomeOverviewAction(label: display.text('home.action.clipboardShelfRef.label'), subtitle: display.text('home.action.clipboardShelfRef.subtitle'), icon: Icons.inventory_2_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardShelf)),
                    HomeOverviewAction(label: display.text('nowTimeline.title'), subtitle: display.text('home.action.nowTimeline.subtitle'), icon: Icons.public_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.nowTimeline)),
                    HomeOverviewAction(label: display.text('coordinate.title'), subtitle: display.text('home.action.coordinateTool.subtitle'), icon: Icons.my_location_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.coordinateTool)),
                    HomeOverviewAction(label: display.text('boundingBox.title'), subtitle: display.text('home.action.boundingBox.subtitle'), icon: Icons.crop_free_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.boundingBox)),
                    HomeOverviewAction(label: display.text('home.action.clipboardWorkbenchRef.label'), subtitle: display.text('home.action.clipboardWorkbenchRef.subtitle'), icon: Icons.content_paste_go_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardWorkbench)),
                    HomeOverviewAction(label: display.text('home.action.hub.label'), subtitle: display.text('home.action.hub.subtitle'), icon: Icons.map_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.hub)),
                    HomeOverviewAction(label: display.text('home.action.uiShowcase.label'), subtitle: display.text('home.action.uiShowcase.subtitle'), icon: Icons.dashboard_customize_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.uiShowcase)),
                    HomeOverviewAction(label: display.text('home.action.apiIntegration.label'), subtitle: display.text('home.action.apiIntegration.subtitle'), icon: Icons.http_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.externalApi)),
                    HomeOverviewAction(label: display.text('home.action.mcpIntegration.label'), subtitle: display.text('home.action.mcpIntegration.subtitle'), icon: Icons.hub_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.externalMcp)),
                    HomeOverviewAction(label: display.text('home.action.counterPlaygroundRef.label'), subtitle: display.text('home.action.counterPlaygroundRef.subtitle'), icon: Icons.exposure_plus_1_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.counterPlayground)),
                    HomeOverviewAction(label: display.text('home.action.ironyGeneratorRef.label'), subtitle: display.text('home.action.ironyGeneratorRef.subtitle'), icon: Icons.auto_awesome_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.ironyGenerator)),
                    HomeOverviewAction(label: display.text('home.action.compositionStudio.label'), subtitle: display.text('home.action.compositionStudio.subtitle'), icon: Icons.music_note_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.compositionGenerator)),
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
