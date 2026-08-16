import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../shared/widgets/home_overview_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime get nowadays => DateTime.now();

  String get today {
    const weekdays = <String>['月', '火', '水', '木', '金', '土', '日'];
    final value = nowadays;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final weekday = weekdays[value.weekday - 1];
    return '${value.year}/$month/$day($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home 🏠'),
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
                Text(today, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                HomeOverviewPanel(
                  actions: [
                    HomeOverviewAction(
                      label: 'Clipboard Shelf · Core Tool #1',
                      subtitle: 'Keep a temporary session-only history of text, URLs, Markdown and 2/3-scaled images; select, sort and bundle-copy it.',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardShelf),
                    ),
                    HomeOverviewAction(
                      label: 'Clipboard Workbench',
                      subtitle: 'Turn shelf/source material into a structured system prompt and copy the result.',
                      icon: Icons.content_paste_go_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.clipboardWorkbench),
                    ),
                    HomeOverviewAction(
                      label: 'Navigation Hub',
                      subtitle: 'Browse the 198 navigation catalogue screens.',
                      icon: Icons.map_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.hub),
                    ),
                    HomeOverviewAction(
                      label: 'UI Showcase',
                      subtitle: 'Material controls, responsive layout, theme and media examples.',
                      icon: Icons.dashboard_customize_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.uiShowcase),
                    ),
                    HomeOverviewAction(
                      label: 'API Integration',
                      subtitle: 'Exercise success, timeout, auth and server-error scenarios.',
                      icon: Icons.http_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.externalApi),
                    ),
                    HomeOverviewAction(
                      label: 'MCP Integration',
                      subtitle: 'Inspect tool-list and tool-call integration behavior.',
                      icon: Icons.hub_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.externalMcp),
                    ),
                    HomeOverviewAction(
                      label: 'Counter Playground',
                      subtitle: 'State transitions, history and interaction basics.',
                      icon: Icons.exposure_plus_1_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.counterPlayground),
                    ),
                    HomeOverviewAction(
                      label: 'Irony Generator',
                      subtitle: 'Generate, favorite and revisit lightweight text results.',
                      icon: Icons.auto_awesome_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.ironyGenerator),
                    ),
                    HomeOverviewAction(
                      label: 'Composition Generator',
                      subtitle: 'Explore key, tempo, progression and customization controls.',
                      icon: Icons.music_note_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.compositionGenerator),
                    ),
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
