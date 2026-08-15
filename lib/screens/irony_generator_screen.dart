import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
import '../data/ironies.dart';
import '../widgets/nav_button.dart';

class IronyGeneratorScreen extends StatefulWidget {
  const IronyGeneratorScreen({super.key});

  @override
  State<IronyGeneratorScreen> createState() => _IronyGeneratorScreenState();
}

class _IronyGeneratorScreenState extends State<IronyGeneratorScreen> {
  final Random _random = Random();
  final List<IronyEntry> _history = [];
  final Set<String> _favorites = {};
  String _tone = 'All';
  late IronyEntry _current;

  @override
  void initState() {
    super.initState();
    _current = Ironies.entries[_random.nextInt(Ironies.entries.length)];
    _history.add(_current);
  }

  List<IronyEntry> get _pool => _tone == 'All'
      ? Ironies.entries
      : Ironies.entries.where((entry) => entry.tone == _tone).toList();

  IronyEntry _pickNext(List<IronyEntry> pool) {
    IronyEntry next = pool[_random.nextInt(pool.length)];
    if (pool.length > 1) {
      while (next.text == _current.text) {
        next = pool[_random.nextInt(pool.length)];
      }
    }
    return next;
  }

  void _generate() {
    final pool = _pool;
    if (pool.isEmpty) return;
    final next = _pickNext(pool);
    setState(() {
      _current = next;
      _history.insert(0, next);
      if (_history.length > 8) _history.removeLast();
    });
  }

  void _selectTone(String tone) {
    if (_tone == tone) return;
    final pool = tone == 'All'
        ? Ironies.entries
        : Ironies.entries.where((entry) => entry.tone == tone).toList();
    if (pool.isEmpty) return;
    final next = _pickNext(pool);
    setState(() {
      _tone = tone;
      _current = next;
      _history.insert(0, next);
      if (_history.length > 8) _history.removeLast();
    });
  }

  void _toggleFavorite() {
    setState(() {
      if (!_favorites.add(_current.text)) {
        _favorites.remove(_current.text);
      }
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _current.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFavorite = _favorites.contains(_current.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irony Generator 🥐'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _tone == 'All',
                      onSelected: (_) => _selectTone('All'),
                    ),
                    ...Ironies.tones.map(
                      (tone) => ChoiceChip(
                        label: Text(tone),
                        selected: _tone == tone,
                        onSelected: (_) => _selectTone(tone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Chip(label: Text(_current.tone)),
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          label: 'Generated irony: ${_current.text}',
                          child: ExcludeSemantics(
                            child: Text(
                              _current.text,
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _generate,
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('Generate again'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                              label: Text(isFavorite ? 'Favorited' : 'Favorite'),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Copy irony',
                              onPressed: _copy,
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Recent generations · ${_favorites.length} favorite${_favorites.length == 1 ? '' : 's'}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ..._history.take(5).map(
                          (entry) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Text(entry.tone),
                            title: Text(entry.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: _favorites.contains(entry.text)
                                ? const Icon(Icons.favorite, size: 18)
                                : null,
                            onTap: () => setState(() => _current = entry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(label: 'Home 🏠', routeName: AppRoutes.home),
                    NavButton(label: 'Counter Playground 👾', routeName: AppRoutes.counterPlayground),
                    NavButton(label: 'Composition Generator 🎸', routeName: AppRoutes.compositionGenerator),
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
