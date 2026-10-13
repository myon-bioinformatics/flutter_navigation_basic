import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../domain/home_controller.dart';
import '../../../config/routes.dart';
import '../../../screens/generic_screen.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/navigation/app_tools.dart';
import '../../../shared/diagnostics/build_diagnostics_card.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/home_overview_panel.dart';

/// A Home card and its corresponding Door entry share this exact title.
String homeDiscoveryLabel(ScreenData screen) => screen.useCaseJa.isNotEmpty
    ? 'Screen${screen.screenDataId} · ${screen.useCaseJa}'
    : 'Screen${screen.screenDataId} · ${screen.title}';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, this.discoveryRandom});

  final HomeController controller;
  final Random? discoveryRandom;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Picks a precomputed Python-generated draw, filtering against the live catalog.
/// The draw index is chosen on every refresh, not frozen at build time.
List<ScreenData> pickHomeDiscoveryScreens(
  List<ScreenData> screens,
  List<List<int>> draws, {
  Random? random,
}) {
  final eligible = {
    for (final s in screens)
      if (s.screenDataId >= 6 && s.screenDataId <= 198) s.screenDataId: s,
  };
  if (eligible.isEmpty || draws.isEmpty) return const [];
  final chosen = draws[(random ?? Random()).nextInt(draws.length)];
  final ids = <int>{};
  // A partial/synthetic catalog may not contain every proposed id.
  // Fill from its own known entries without introducing invalid routes.
  for (final id in [...chosen, ...eligible.keys]) {
    if (eligible.containsKey(id)) ids.add(id);
    if (ids.length == 3) break;
  }
  return [for (final id in ids) eligible[id]!];
}

Future<List<List<int>>> loadHomeDiscoveryDraws() async {
  final raw = await rootBundle.loadString('assets/home_discovery_draws.json');
  final parsed = jsonDecode(raw) as Map<String, dynamic>;
  if (parsed['schema'] != 1) throw const FormatException('unknown discovery schema');
  final rows = (parsed['draws'] as List).map((row) =>
      (row as List).map((id) => id as int).toList()).toList();
  if (rows.isEmpty || rows.any((row) =>
      row.length != 3 || row.toSet().length != 3 ||
      row.any((id) => id < 6 || id > 198))) {
    throw const FormatException('invalid discovery draws');
  }
  return rows;
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScreenData> _discoveries = const [];
  int _generation = 0;
  List<List<int>>? _draws;

  @override
  void initState() {
    super.initState();
    _reshuffle();
  }

  Future<void> _reshuffle() async {
    final generation = ++_generation;
    try {
      final screens = await ScreensConfig.load();
      final draws = _draws ?? await loadHomeDiscoveryDraws();
      if (!mounted || generation != _generation) return;
      _draws = draws;
      final selected = pickHomeDiscoveryScreens(
        screens,
        draws,
        random: widget.discoveryRandom,
      );
      setState(() => _discoveries = selected);
      HomeDoorCatalog.instance.updateDiscoveries([
        for (final screen in selected)
          AppTool(
            routeName: AppRoutes.screenRoute(screen.screenDataId),
            label: homeDiscoveryLabel(screen),
          ),
      ]);
    } catch (_) {
      // Discovery is optional: leave the main tools available if the asset fails.
      if (mounted && generation == _generation) {
        setState(() => _discoveries = const []);
        HomeDoorCatalog.instance.clearDiscoveries();
      }
    }
  }

  void _refresh() {
    _reshuffle();
    setState(() {});
  }

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
                    for (final tool in homeAppTools)
                      HomeOverviewAction(
                        label: display.text(tool.homeLabelKey ?? tool.labelKey!),
                        subtitle: display.text(tool.homeSubtitleKey!),
                        icon: tool.homeIcon!,
                        onTap: () => Navigator.of(context).pushNamed(tool.routeName),
                      ),
                    for (final screen in _discoveries)
                      HomeOverviewAction(
                        label: homeDiscoveryLabel(screen),
                        subtitle: screen.description,
                        icon: Icons.shuffle_outlined,
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.screenRoute(screen.screenDataId)),
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
