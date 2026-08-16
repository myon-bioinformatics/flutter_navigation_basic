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
                      label: 'Composition Generator',
                      subtitle: 'Explore key, tempo, progression and customization controls.',
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
