import 'package:flutter/material.dart';
import '../domain/home_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/diagnostics/build_diagnostics_card.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/home_overview_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Home 🏠'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(controller.today, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                HomeOverviewPanel(
                  actions: [
                    HomeOverviewAction(
                      label: 'Clipboard Shelf · Core Tool #1',
                      subtitle: 'Session-only history for text, URLs, Markdown and 2/3-scaled images with filter, ordering and bundle copy.',
                      icon: Icons.inventory_2_outlined,
                      onTap: AppNavigation.toClipboardShelf,
                    ),
                    HomeOverviewAction(
                      label: 'Now Timeline',
                      subtitle: 'Put people, places, schedules and events from different IANA time zones on one client-side timeline.',
                      icon: Icons.public_outlined,
                      onTap: AppNavigation.toNowTimeline,
                    ),
                    HomeOverviewAction(
                      label: 'Clipboard Workbench',
                      subtitle: 'Turn source material into a structured system prompt and copy the result.',
                      icon: Icons.content_paste_go_outlined,
                      onTap: AppNavigation.toClipboardWorkbench,
                    ),
                    HomeOverviewAction(
                      label: 'Counter Playground',
                      subtitle: 'State transitions, undo/history and interaction basics.',
                      icon: Icons.exposure_plus_1_outlined,
                      onTap: AppNavigation.toCounterPlayground,
                    ),
                    HomeOverviewAction(
                      label: 'Irony Generator',
                      subtitle: 'Generate lightweight text results and revisit favorites.',
                      icon: Icons.auto_awesome_outlined,
                      onTap: AppNavigation.toIronyGenerator,
                    ),
                    HomeOverviewAction(
                      label: 'Composition Studio',
                      subtitle: 'Visual metronome, tap tempo, song structure, lyrics and chords in one lightweight pre-DAW workspace.',
                      icon: Icons.music_note_outlined,
                      onTap: AppNavigation.toCompositionGenerator,
                    ),
                    HomeOverviewAction(
                      label: 'URL Parameters',
                      subtitle: 'Inspect route/query-style parameter handling.',
                      icon: Icons.link_outlined,
                      onTap: AppNavigation.toScreen5,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const BuildDiagnosticsCard(screenId: 'home'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
