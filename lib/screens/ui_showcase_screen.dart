import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/routes.dart';
import '../shared/display/display_scope.dart';

class UiShowcaseConfig {
  static const UiShowcaseConfig defaults = UiShowcaseConfig(
    title: 'UI Showcase',
    subtitle: 'Internal defaults keep the screen usable without external config.',
    defaultStyle: 'modern',
    defaultBrightness: 'system',
    sections: <String>['Overview', 'Components', 'Data', 'Media'],
    imageBase64: '',
  );

  final String title;
  final String subtitle;
  final String defaultStyle;
  final String defaultBrightness;
  final List<String> sections;
  final String imageBase64;

  const UiShowcaseConfig({
    required this.title,
    required this.subtitle,
    required this.defaultStyle,
    required this.defaultBrightness,
    required this.sections,
    required this.imageBase64,
  });

  factory UiShowcaseConfig.fromExternal(Map<String, dynamic> json) {
    String value(String key, String fallback) {
      final candidate = json[key];
      return candidate is String && candidate.trim().isNotEmpty
          ? candidate.trim()
          : fallback;
    }

    final rawSections = json['sections'];
    final sections = rawSections is List
        ? rawSections.whereType<String>().where((item) => item.isNotEmpty).toList()
        : <String>[];

    return UiShowcaseConfig(
      title: value('title', defaults.title),
      subtitle: value('subtitle', defaults.subtitle),
      defaultStyle: value('defaultStyle', defaults.defaultStyle),
      defaultBrightness: value('defaultBrightness', defaults.defaultBrightness),
      sections: sections.length == 4 ? sections : defaults.sections,
      imageBase64: value('imageBase64', defaults.imageBase64),
    );
  }

  static Future<UiShowcaseConfig> load() async {
    try {
      final raw = await rootBundle.loadString('assets/ui_showcase.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UiShowcaseConfig.fromExternal(decoded);
      }
    } catch (_) {
      // Internal defaults are the deliberate fallback for missing/bad overrides.
    }
    return defaults;
  }
}

class UiShowcaseScreen extends StatefulWidget {
  const UiShowcaseScreen({super.key});

  @override
  State<UiShowcaseScreen> createState() => _UiShowcaseScreenState();
}

class _UiShowcaseScreenState extends State<UiShowcaseScreen> {
  UiShowcaseConfig? _config;
  var _selectedIndex = 0;
  var _style = 'modern';
  var _brightnessMode = 'system';
  var _notifications = true;
  var _density = 0.5;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await UiShowcaseConfig.load();
    if (!mounted) return;
    setState(() {
      _config = config;
      _style = _normalizeStyle(config.defaultStyle);
      _brightnessMode = _normalizeBrightness(config.defaultBrightness);
    });
  }

  String _normalizeStyle(String value) =>
      const {'modern', 'retro', 'terminal'}.contains(value) ? value : 'modern';

  String _normalizeBrightness(String value) =>
      const {'system', 'light', 'dark'}.contains(value) ? value : 'system';

  Brightness _brightness(BuildContext context) {
    switch (_brightnessMode) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      default:
        return MediaQuery.platformBrightnessOf(context);
    }
  }

  Color _seedColor() {
    switch (_style) {
      case 'retro':
        return Colors.deepOrange;
      case 'terminal':
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }

  ThemeData _themeFor(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: _brightness(context),
      colorSchemeSeed: _seedColor(),
      fontFamily: _style == 'terminal' ? 'monospace' : null,
    );
  }

  List<NavigationRailDestination> _railDestinations(UiShowcaseConfig config) {
    const icons = <IconData>[
      Icons.dashboard_outlined,
      Icons.widgets_outlined,
      Icons.table_chart_outlined,
      Icons.image_outlined,
    ];
    return List.generate(
      4,
      (index) => NavigationRailDestination(
        icon: Icon(icons[index]),
        label: Text(config.sections[index]),
      ),
    );
  }

  List<NavigationDestination> _bottomDestinations(UiShowcaseConfig config) {
    const icons = <IconData>[
      Icons.dashboard_outlined,
      Icons.widgets_outlined,
      Icons.table_chart_outlined,
      Icons.image_outlined,
    ];
    return List.generate(
      4,
      (index) => NavigationDestination(
        icon: Icon(icons[index]),
        label: config.sections[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final display = DisplayScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return Theme(
      data: _themeFor(context),
      child: Builder(
        builder: (themedContext) => Scaffold(
          appBar: AppBar(
            title: Text(config.title),
            actions: [
              PopupMenuButton<String>(
                tooltip: display.text('uiShowcase.designStyleTooltip'),
                initialValue: _style,
                onSelected: (value) => setState(() => _style = value),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'modern', child: Text(display.text('uiShowcase.styleModern'))),
                  PopupMenuItem(value: 'retro', child: Text(display.text('uiShowcase.styleRetro'))),
                  PopupMenuItem(value: 'terminal', child: Text(display.text('uiShowcase.styleTerminal'))),
                ],
                icon: const Icon(Icons.palette_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: display.text('uiShowcase.brightnessTooltip'),
                initialValue: _brightnessMode,
                onSelected: (value) => setState(() => _brightnessMode = value),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'system', child: Text(display.text('uiShowcase.brightnessSystem'))),
                  PopupMenuItem(value: 'light', child: Text(display.text('uiShowcase.brightnessLight'))),
                  PopupMenuItem(value: 'dark', child: Text(display.text('uiShowcase.brightnessDark'))),
                ],
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              IconButton(
                tooltip: display.text('uiShowcase.homeTooltip'),
                onPressed: () => Navigator.pushNamed(themedContext, AppRoutes.home),
                icon: const Icon(Icons.home_outlined),
              ),
              const DisplayLocalePicker(compact: true),
            ],
          ),
          drawer: narrow
              ? Drawer(
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        ListTile(
                          title: Text(config.title),
                          subtitle: Text(display.text('uiShowcase.standardNavigation')),
                        ),
                        const Divider(),
                        for (var i = 0; i < config.sections.length; i++)
                          ListTile(
                            selected: _selectedIndex == i,
                            leading: Icon(_bottomDestinations(config)[i].icon is Icon
                                ? (_bottomDestinations(config)[i].icon as Icon).icon
                                : Icons.circle_outlined),
                            title: Text(config.sections[i]),
                            onTap: () {
                              Navigator.of(themedContext).pop();
                              setState(() => _selectedIndex = i);
                            },
                          ),
                      ],
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!narrow)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  extended: MediaQuery.sizeOf(themedContext).width >= 1180,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  destinations: _railDestinations(config),
                ),
              if (!narrow) const VerticalDivider(width: 1),
              Expanded(
                child: _ShowcaseContent(
                  config: config,
                  selectedIndex: _selectedIndex,
                  style: _style,
                  brightnessMode: _brightnessMode,
                  notifications: _notifications,
                  density: _density,
                  searchController: _searchController,
                  onNotificationsChanged: (value) =>
                      setState(() => _notifications = value),
                  onDensityChanged: (value) => setState(() => _density = value),
                ),
              ),
            ],
          ),
          bottomNavigationBar: narrow
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  destinations: _bottomDestinations(config),
                )
              : null,
        ),
      ),
    );
  }
}

class _ShowcaseContent extends StatelessWidget {
  final UiShowcaseConfig config;
  final int selectedIndex;
  final String style;
  final String brightnessMode;
  final bool notifications;
  final double density;
  final TextEditingController searchController;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<double> onDensityChanged;

  const _ShowcaseContent({
    required this.config,
    required this.selectedIndex,
    required this.style,
    required this.brightnessMode,
    required this.notifications,
    required this.density,
    required this.searchController,
    required this.onNotificationsChanged,
    required this.onDensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _OverviewPage(
        config: config,
        style: style,
        brightnessMode: brightnessMode,
      ),
      _ComponentsPage(
        notifications: notifications,
        density: density,
        searchController: searchController,
        onNotificationsChanged: onNotificationsChanged,
        onDensityChanged: onDensityChanged,
      ),
      const _DataPage(),
      _MediaPage(imageBase64: config.imageBase64),
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey(selectedIndex),
        child: pages[selectedIndex],
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  final UiShowcaseConfig config;
  final String style;
  final String brightnessMode;

  const _OverviewPage({
    required this.config,
    required this.style,
    required this.brightnessMode,
  });

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(config.subtitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(display.text('uiShowcase.internalDefaultsChip'))),
            Chip(label: Text(display.text('uiShowcase.externalOverridesChip'))),
            Chip(label: Text(display.text('uiShowcase.material3Chip'))),
            Chip(label: Text(display.text('uiShowcase.styleChipLabel', arguments: {'style': style}))),
            Chip(label: Text(display.text('uiShowcase.brightnessChipLabel', arguments: {'mode': brightnessMode}))),
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          icon: Icons.view_sidebar_outlined,
          title: display.text('uiShowcase.infoResponsiveTitle'),
          text: display.text('uiShowcase.infoResponsiveText'),
        ),
        _InfoCard(
          icon: Icons.tune_outlined,
          title: display.text('uiShowcase.infoConfigTitle'),
          text: display.text('uiShowcase.infoConfigText'),
        ),
        _InfoCard(
          icon: Icons.layers_outlined,
          title: display.text('uiShowcase.infoCouplingTitle'),
          text: display.text('uiShowcase.infoCouplingText'),
        ),
      ],
    );
  }
}

class _ComponentsPage extends StatelessWidget {
  final bool notifications;
  final double density;
  final TextEditingController searchController;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<double> onDensityChanged;

  const _ComponentsPage({
    required this.notifications,
    required this.density,
    required this.searchController,
    required this.onNotificationsChanged,
    required this.onDensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(display.text('uiShowcase.commonControls'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: display.text('uiShowcase.searchLabel'),
            hintText: display.text('uiShowcase.searchHint'),
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(onPressed: () {}, child: Text(display.text('uiShowcase.primaryButton'))),
            OutlinedButton(onPressed: () {}, child: Text(display.text('uiShowcase.secondaryButton'))),
            FilterChip(label: Text(display.text('uiShowcase.filterChip')), selected: true, onSelected: null),
            InputChip(label: Text(display.text('uiShowcase.tagChip'))),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(display.text('uiShowcase.notificationsTitle')),
          subtitle: Text(display.text('uiShowcase.notificationsSubtitle')),
          value: notifications,
          onChanged: onNotificationsChanged,
        ),
        ListTile(
          title: Text(display.text('uiShowcase.densityTitle')),
          subtitle: Slider(
            value: density,
            onChanged: onDensityChanged,
          ),
          trailing: Text('${(density * 100).round()}%'),
        ),
        ExpansionTile(
          title: Text(display.text('uiShowcase.expandableTitle')),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(display.text('uiShowcase.expandableText')),
            ),
          ],
        ),
      ],
    );
  }
}

class _DataPage extends StatelessWidget {
  const _DataPage();

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(display.text('uiShowcase.dataPresentation'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Pattern')),
              DataColumn(label: Text('Coverage')),
              DataColumn(label: Text('Dependency')),
            ],
            rows: const [
              DataRow(cells: [
                DataCell(Text('Navigation')),
                DataCell(Text('Rail / Drawer / Bottom')),
                DataCell(Text('Flutter SDK')),
              ]),
              DataRow(cells: [
                DataCell(Text('Theme')),
                DataCell(Text('System / Light / Dark')),
                DataCell(Text('Flutter SDK')),
              ]),
              DataRow(cells: [
                DataCell(Text('Media')),
                DataCell(Text('Base64 image')),
                DataCell(Text('dart:convert')),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(display.text('uiShowcase.apiMcpShellTitle')),
            subtitle: Text(display.text('uiShowcase.apiMcpShellText')),
          ),
        ),
      ],
    );
  }
}

class _MediaPage extends StatelessWidget {
  final String imageBase64;

  const _MediaPage({required this.imageBase64});

  Uint8List? _decodeImage() {
    if (imageBase64.isEmpty) return null;
    try {
      return base64Decode(imageBase64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final bytes = _decodeImage();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(display.text('uiShowcase.embeddedMedia'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(display.text('uiShowcase.embeddedMediaText')),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? const Center(child: Icon(Icons.broken_image_outlined, size: 64))
                : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.video_library_outlined),
          title: Text(display.text('uiShowcase.videoOptionalTitle')),
          subtitle: Text(display.text('uiShowcase.videoOptionalText')),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
