import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
import '../shared/display/display_scope.dart';
import 'pattern_template_screen.dart';

class ScreenDetail {
  final String purpose;
  final String when;
  final List<String> points;
  final String pitfall;
  final String snippet;

  const ScreenDetail({
    required this.purpose,
    required this.when,
    required this.points,
    required this.pitfall,
    required this.snippet,
  });

  factory ScreenDetail.fromJson(Map<String, dynamic> json) => ScreenDetail(
        purpose: json['purpose'] as String? ?? '',
        when: json['when'] as String? ?? '',
        points: (json['points'] as List?)?.map((e) => e as String).toList() ??
            const [],
        pitfall: json['pitfall'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
      );
}

class ScreenData {
  final int screenDataId;
  final String name;
  final String title;
  final String emoji;
  final String description;
  final String category;
  final String navigationPattern;
  final String apiPattern;
  final String themePattern;
  final String dataPattern;
  final String domainKey;
  final String domainJa;
  final String domainEmoji;
  final String useCaseJa;
  final String useCaseEn;
  final String useCaseKey;
  final String templateJa;
  final String? templateOverride;
  final ScreenDetail? detail;

  const ScreenData({
    required this.screenDataId,
    required this.name,
    required this.title,
    required this.emoji,
    required this.description,
    required this.category,
    required this.navigationPattern,
    required this.apiPattern,
    required this.themePattern,
    required this.dataPattern,
    this.domainKey = '',
    this.domainJa = '',
    this.domainEmoji = '',
    this.useCaseJa = '',
    this.useCaseEn = '',
    this.useCaseKey = '',
    this.templateJa = '',
    this.templateOverride,
    this.detail,
  });

  factory ScreenData.fromJson(Map<String, dynamic> json) => ScreenData(
        screenDataId: (json['screenDataId'] ?? json['id']) as int,
        name: json['name'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        navigationPattern: json['navigationPattern'] as String,
        apiPattern: json['apiPattern'] as String,
        themePattern: json['themePattern'] as String,
        dataPattern: json['dataPattern'] as String,
        domainKey: json['domainKey'] as String? ?? '',
        domainJa: json['domainJa'] as String? ?? '',
        domainEmoji: json['domainEmoji'] as String? ?? '',
        useCaseJa: json['useCaseJa'] as String? ?? '',
        useCaseEn: json['useCaseEn'] as String? ?? '',
        useCaseKey: json['useCaseKey'] as String? ?? '',
        templateJa: json['templateJa'] as String? ?? '',
        templateOverride: json['templateOverride'] as String?,
        detail: json['detail'] == null
            ? null
            : ScreenDetail.fromJson(json['detail'] as Map<String, dynamic>),
      );
}

class ScreensConfig {
  static List<ScreenData>? _cache;

  static Future<List<ScreenData>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/screens.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['screens'] as List)
        .map((e) => ScreenData.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}

class GenericScreen extends StatefulWidget {
  final int screenId;
  const GenericScreen({super.key, required this.screenId});

  @override
  State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> {
  ScreenData? _data;
  List<ScreenData> _screens = const [];
  Object? _loadError;
  final FocusNode _backToHubFocus = FocusNode(debugLabel: 'back-to-hub');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final screens = await ScreensConfig.load();
      final data = screens.firstWhere(
        (s) => s.screenDataId == widget.screenId,
        orElse: () => ScreenData(
          screenDataId: widget.screenId,
          name: 'Screen${widget.screenId}',
          title: 'Screen ${widget.screenId}',
          emoji: '📱',
          description: '',
          category: 'navigation',
          navigationPattern: '',
          apiPattern: '',
          themePattern: '',
          dataPattern: '',
        ),
      );
      if (!mounted) return;
      setState(() {
        _screens = screens;
        _data = data;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _screens = const [];
        _data = null;
        _loadError = error;
      });
    }
  }

  void _backToHub() => Navigator.pushNamed(context, AppRoutes.hub);

  @override
  void dispose() {
    _backToHubFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final data = _data;
    final hasUseCase = data != null && data.useCaseJa.isNotEmpty;
    final appBarTitle = data == null
        ? display.text('generic.screenFallbackTitle', arguments: {'screenDataId': widget.screenId})
        : hasUseCase
            ? '${data.emoji} ${data.useCaseJa}'
            : 'Screen${data.screenDataId}: ${data.title} ${data.emoji}';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Semantics(
            identifier: 'back-to-hub',
            button: true,
            enabled: true,
            focusable: true,
            label: display.text('generic.backToHub'),
            onTap: _backToHub,
            onFocus: _backToHubFocus.requestFocus,
            excludeSemantics: true,
            child: IconButton(
              key: const Key('back-to-hub'),
              focusNode: _backToHubFocus,
              tooltip: display.text('generic.backToHub'),
              onPressed: _backToHub,
              icon: const Icon(Icons.grid_view),
            ),
          ),
        ],
      ),
      body: data == null
          ? _loadError == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Semantics(
                    identifier: 'screen-catalog-load-error',
                    container: true,
                    child: FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: Text(display.text('common.refresh')),
                    ),
                  ),
                )
          : _GenericScreenBody(
              data: data,
              allScreens: _screens,
              onBackToHub: _backToHub,
            ),
    );
  }
}

class _GenericScreenBody extends StatelessWidget {
  final ScreenData data;
  final List<ScreenData> allScreens;
  final VoidCallback onBackToHub;

  const _GenericScreenBody({
    required this.data,
    required this.allScreens,
    required this.onBackToHub,
  });

  bool get _hasDomainInfo => data.domainJa.isNotEmpty && data.templateJa.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final headline = data.useCaseJa.isNotEmpty
        ? data.useCaseJa
        : templateLabel(display, templateForScreenId(data.screenDataId));
    final subline = _hasDomainInfo
        ? '${data.domainEmoji} ${data.domainJa} · ${data.templateJa}テンプレート · Screen ${data.screenDataId}'
        : display.text(
            'generic.templateVariant',
            arguments: {
              'n': (data.screenDataId - 1) ~/ 18 + 1,
              'v': (data.screenDataId - 1) % 18 + 1,
            },
          );
    final detail = data.detail;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(data.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          subline,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onBackToHub,
                    icon: const Icon(Icons.grid_view),
                    label: Text(display.text('generic.backToHub')),
                  ),
                ],
              ),
              if (detail == null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PatternChip(label: display.text('generic.patternNavigation'), value: data.navigationPattern),
                    _PatternChip(label: display.text('generic.patternApi'), value: data.apiPattern),
                    _PatternChip(label: display.text('generic.patternTheme'), value: data.themePattern),
                    _PatternChip(label: display.text('generic.patternData'), value: data.dataPattern),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: data.screenDataId == 6
              ? _Screen6CatalogSearch(screens: allScreens)
              : detail == null
                  ? PatternTemplateBody(
                      screenId: data.screenDataId,
                      title: data.title,
                      description: data.description,
                      templateOverride: data.templateOverride,
                    )
                  : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: display.text('generic.tabUseCase')),
                          Tab(text: display.text('generic.tabUiSample')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _UseCaseTab(data: data, detail: detail),
                            PatternTemplateBody(
                              screenId: data.screenDataId,
                              title: data.title,
                              description: data.description,
                              templateOverride: data.templateOverride,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Screen6CatalogSearch extends StatefulWidget {
  const _Screen6CatalogSearch({required this.screens});

  final List<ScreenData> screens;

  @override
  State<_Screen6CatalogSearch> createState() => _Screen6CatalogSearchState();
}

class _Screen6CatalogSearchState extends State<_Screen6CatalogSearch> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<ScreenData> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.screens;
    return widget.screens.where((screen) {
      final haystack = <String>[
        screen.screenDataId.toString(),
        'screen${screen.screenDataId}',
        screen.name,
        screen.title,
        screen.domainKey,
        screen.domainJa,
        screen.useCaseJa,
        screen.useCaseEn,
        screen.useCaseKey,
        screen.description,
      ].join('\n').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _open(ScreenData screen) {
    if (screen.screenDataId == 6) return;
    Navigator.pushNamed(context, AppRoutes.screenRoute(screen.screenDataId));
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('screen6-catalog-search'),
            controller: _queryController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: display.text('hub.searchHint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('screen6-catalog-clear'),
                      tooltip: 'Clear',
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Text(
            '${filtered.length} / ${widget.screens.length}',
            key: const Key('screen6-result-count'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(display.text('hub.empty')))
                : ListView.separated(
                    key: const Key('screen6-catalog-results'),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final screen = filtered[index];
                      final isCurrent = screen.screenDataId == 6;
                      return ListTile(
                        key: Key('screen6-result-${screen.screenDataId}'),
                        leading: Text(
                          screen.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          'Screen ${screen.screenDataId} · ${screen.useCaseJa.isEmpty ? screen.title : screen.useCaseJa}',
                        ),
                        subtitle: Text(
                          [
                            if (screen.useCaseEn.isNotEmpty) screen.useCaseEn,
                            if (screen.domainJa.isNotEmpty)
                              '${screen.domainEmoji} ${screen.domainJa}',
                          ].join(' · '),
                        ),
                        trailing:
                            isCurrent ? const Icon(Icons.search) : const Icon(Icons.chevron_right),
                        onTap: isCurrent ? null : () => _open(screen),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UseCaseTab extends StatelessWidget {
  final ScreenData data;
  final ScreenDetail detail;

  const _UseCaseTab({required this.data, required this.detail});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(display.text('generic.sectionPurpose'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.purpose),
          const SizedBox(height: 16),
          Text(display.text('generic.sectionWhen'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.when),
          const SizedBox(height: 16),
          Text(display.text('generic.sectionPoints'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          ...detail.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $point'),
            ),
          ),
          const SizedBox(height: 16),
          Text(display.text('generic.sectionPitfall'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.pitfall),
          const SizedBox(height: 16),
          Text(display.text('generic.sectionSnippet'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              detail.snippet,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PatternChip(label: display.text('generic.patternNavigation'), value: data.navigationPattern),
              _PatternChip(label: display.text('generic.patternApi'), value: data.apiPattern),
              _PatternChip(label: display.text('generic.patternTheme'), value: data.themePattern),
              _PatternChip(label: display.text('generic.patternData'), value: data.dataPattern),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatternChip extends StatelessWidget {
  final String label;
  final String value;

  const _PatternChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(label.substring(0, 1)),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}
