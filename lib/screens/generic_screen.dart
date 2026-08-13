import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
import 'pattern_template_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          data != null
              ? 'Screen${data.id}: ${data.title} ${data.emoji}'
              : 'Screen ${widget.screenId}',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Back to Hub',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.hub),
            icon: const Icon(Icons.grid_view),
          ),
        ],
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                  templateLabel(templateForScreenId(data.id)),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Template ${(data.id - 1) ~/ 18 + 1} of 11 · variant ${(data.id - 1) % 18 + 1} of 18',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PatternTemplateBody(
                    screenId: data.id,
                    title: data.title,
                    description: data.description,
                  ),
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
