import 'package:flutter/material.dart';
import '../domain/home_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/diagnostics/build_diagnostics_card.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/home_overview_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final weekdayLabels = <String>[
      display.text('common.weekday.mon'),
      display.text('common.weekday.tue'),
      display.text('common.weekday.wed'),
      display.text('common.weekday.thu'),
      display.text('common.weekday.fri'),
      display.text('common.weekday.sat'),
      display.text('common.weekday.sun'),
    ];
    return Scaffold(
      appBar: CustomAppBar(
        title: display.text('home.title'),
        actions: [
          IconButton(
            tooltip: display.text('common.refresh'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.controller.today(weekdayLabels), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                HomeOverviewPanel(
                  title: display.text('homeOverview.title'),
                  subtitle: display.text('homeOverview.subtitle'),
                  actions: [
                    HomeOverviewAction(label: display.text('home.action.clipboardShelfProd.label'), subtitle: display.text('home.action.clipboardShelfProd.subtitle'), icon: Icons.inventory_2_outlined, onTap: AppNavigation.toClipboardShelf),
                    HomeOverviewAction(label: display.text('nowTimeline.title'), subtitle: display.text('home.action.nowTimeline.subtitle'), icon: Icons.public_outlined, onTap: AppNavigation.toNowTimeline),
                    HomeOverviewAction(label: display.text('coordinate.title'), subtitle: display.text('home.action.coordinateTool.subtitle'), icon: Icons.my_location_outlined, onTap: AppNavigation.toCoordinateTool),
                    HomeOverviewAction(label: display.text('boundingBox.title'), subtitle: display.text('home.action.boundingBox.subtitle'), icon: Icons.crop_free_outlined, onTap: AppNavigation.toBoundingBox),
                    HomeOverviewAction(label: display.text('home.action.clipboardWorkbenchProd.label'), subtitle: display.text('home.action.clipboardWorkbenchProd.subtitle'), icon: Icons.content_paste_go_outlined, onTap: AppNavigation.toClipboardWorkbench),
                    HomeOverviewAction(label: display.text('home.action.counterPlaygroundProd.label'), subtitle: display.text('home.action.counterPlaygroundProd.subtitle'), icon: Icons.exposure_plus_1_outlined, onTap: AppNavigation.toCounterPlayground),
                    HomeOverviewAction(label: display.text('home.action.ironyGeneratorProd.label'), subtitle: display.text('home.action.ironyGeneratorProd.subtitle'), icon: Icons.auto_awesome_outlined, onTap: AppNavigation.toIronyGenerator),
                    HomeOverviewAction(label: display.text('home.action.compositionStudio.label'), subtitle: display.text('home.action.compositionStudio.subtitle'), icon: Icons.music_note_outlined, onTap: AppNavigation.toCompositionGenerator),
                    HomeOverviewAction(label: display.text('home.action.urlParameters.label'), subtitle: display.text('home.action.urlParameters.subtitle'), icon: Icons.link_outlined, onTap: AppNavigation.toScreen5),
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
