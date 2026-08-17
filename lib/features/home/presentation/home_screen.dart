import 'package:flutter/material.dart';
import '../domain/home_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/diagnostics/build_diagnostics_card.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/home_overview_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    return Scaffold(
      appBar: CustomAppBar(title: t('home.title')),
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
                    HomeOverviewAction(label: t('home.clipboardShelf'), subtitle: t('home.clipboardShelfSubtitle'), icon: Icons.inventory_2_outlined, onTap: AppNavigation.toClipboardShelf),
                    HomeOverviewAction(label: t('home.nowTimeline'), subtitle: t('home.nowTimelineSubtitle'), icon: Icons.public_outlined, onTap: AppNavigation.toNowTimeline),
                    HomeOverviewAction(label: t('home.coordinates'), subtitle: t('home.coordinatesSubtitle'), icon: Icons.my_location_outlined, onTap: AppNavigation.toCoordinateTool),
                    HomeOverviewAction(label: t('home.workbench'), subtitle: t('home.workbenchSubtitle'), icon: Icons.content_paste_go_outlined, onTap: AppNavigation.toClipboardWorkbench),
                    HomeOverviewAction(label: t('home.counter'), subtitle: t('home.counterSubtitle'), icon: Icons.exposure_plus_1_outlined, onTap: AppNavigation.toCounterPlayground),
                    HomeOverviewAction(label: t('home.irony'), subtitle: t('home.ironySubtitle'), icon: Icons.auto_awesome_outlined, onTap: AppNavigation.toIronyGenerator),
                    HomeOverviewAction(label: t('home.composition'), subtitle: t('home.compositionSubtitle'), icon: Icons.music_note_outlined, onTap: AppNavigation.toCompositionGenerator),
                    HomeOverviewAction(label: t('home.urlParams'), subtitle: t('home.urlParamsSubtitle'), icon: Icons.link_outlined, onTap: AppNavigation.toScreen5),
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
