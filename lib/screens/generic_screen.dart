import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
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
  final int id;
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
    required this.id,
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
        id: json['id'] as int,
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final screens = await ScreensConfig.load();
    final data = screens.firstWhere(
      (s) => s.id == widget.screenId,
      orElse: () => ScreenData(
        id: widget.screenId,
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
    if (mounted) setState(() => _data = data);
  }

  void _backToHub() => Navigator.pushNamed(context, AppRoutes.hub);

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final hasUseCase = data != null && data.useCaseJa.isNotEmpty;
    final appBarTitle = data == null
        ? 'Screen ${widget.screenId}'
        : hasUseCase
            ? '${data.emoji} ${data.useCaseJa}'
            : 'Screen${data.id}: ${data.title} ${data.emoji}';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Back to Hub',
            onPressed: _backToHub,
            icon: const Icon(Icons.grid_view),
          ),
        ],
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : _GenericScreenBody(data: data, onBackToHub: _backToHub),
    );
  }
}

class _GenericScreenBody extends StatelessWidget {
  final ScreenData data;
  final VoidCallback onBackToHub;

  const _GenericScreenBody({required this.data, required this.onBackToHub});

  bool get _hasDomainInfo => data.domainJa.isNotEmpty && data.templateJa.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final headline = data.useCaseJa.isNotEmpty
        ? data.useCaseJa
        : templateLabel(templateForScreenId(data.id));
    final subline = _hasDomainInfo
        ? '${data.domainEmoji} ${data.domainJa} · ${data.templateJa}テンプレート · Screen ${data.id}'
        : 'Template ${(data.id - 1) ~/ 18 + 1} of 11 · variant ${(data.id - 1) % 18 + 1} of 18';
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
                    label: const Text('Back to Hub'),
                  ),
                ],
              ),
              if (detail == null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PatternChip(label: 'Navigation', value: data.navigationPattern),
                    _PatternChip(label: 'API', value: data.apiPattern),
                    _PatternChip(label: 'Theme', value: data.themePattern),
                    _PatternChip(label: 'Data', value: data.dataPattern),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: detail == null
              ? PatternTemplateBody(
                  screenId: data.id,
                  title: data.title,
                  description: data.description,
                  templateOverride: data.templateOverride,
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: '用途'),
                          Tab(text: 'UIサンプル'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _UseCaseTab(data: data, detail: detail),
                            PatternTemplateBody(
                              screenId: data.id,
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

class _UseCaseTab extends StatelessWidget {
  final ScreenData data;
  final ScreenDetail detail;

  const _UseCaseTab({required this.data, required this.detail});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目的', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.purpose),
          const SizedBox(height: 16),
          Text('使いどころ', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.when),
          const SizedBox(height: 16),
          Text('設計ポイント', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          ...detail.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $point'),
            ),
          ),
          const SizedBox(height: 16),
          Text('落とし穴', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(detail.pitfall),
          const SizedBox(height: 16),
          Text('スニペット', style: textTheme.titleSmall),
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
              _PatternChip(label: 'Navigation', value: data.navigationPattern),
              _PatternChip(label: 'API', value: data.apiPattern),
              _PatternChip(label: 'Theme', value: data.themePattern),
              _PatternChip(label: 'Data', value: data.dataPattern),
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
