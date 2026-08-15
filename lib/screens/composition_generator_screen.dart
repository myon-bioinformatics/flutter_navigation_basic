import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
import '../data/composer.dart';
import '../widgets/nav_button.dart';

class CompositionGeneratorScreen extends StatefulWidget {
  const CompositionGeneratorScreen({super.key});

  @override
  State<CompositionGeneratorScreen> createState() => _CompositionGeneratorScreenState();
}

class _CompositionGeneratorScreenState extends State<CompositionGeneratorScreen> {
  final Random _random = Random();
  final List<String> _history = [];

  late String _tonicKey;
  late int _bpm;
  late String _mode;
  late String _timeSignature;
  late String _progression;

  @override
  void initState() {
    super.initState();
    _generate(initial: true);
  }

  List<String> get _progressionPool =>
      _mode == 'Major' ? Composer.progressionsMajor : Composer.progressionsMinor;

  String get _resultText =>
      'Key: $_tonicKey $_mode · BPM: $_bpm · Time: $_timeSignature · Progression: $_progression';

  void _generate({bool initial = false}) {
    final key = Composer.diatonicScaleList[
        _random.nextInt(Composer.diatonicScaleList.length)];
    final mode = Composer.modes[_random.nextInt(Composer.modes.length)];
    final bpm = 80 + _random.nextInt(81);
    final timeSignature = Composer.timeSignatures[
        _random.nextInt(Composer.timeSignatures.length)];
    final progressions = mode == 'Major'
        ? Composer.progressionsMajor
        : Composer.progressionsMinor;
    final progression = progressions[_random.nextInt(progressions.length)];

    void assign() {
      _tonicKey = key;
      _mode = mode;
      _bpm = bpm;
      _timeSignature = timeSignature;
      _progression = progression;
      _history.insert(0, _resultText);
      if (_history.length > 6) _history.removeLast();
    }

    if (initial) {
      assign();
    } else {
      setState(assign);
    }
  }

  void _regenerateProgression() {
    setState(() {
      final pool = _progressionPool;
      _progression = pool[_random.nextInt(pool.length)];
      _history.insert(0, _resultText);
      if (_history.length > 6) _history.removeLast();
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _resultText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Composition idea copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composition Generator 🎸'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Song seed', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('$_tonicKey $_mode')),
                            Chip(label: Text('$_bpm BPM')),
                            Chip(label: Text(_timeSignature)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          label: 'Chord progression $_progression',
                          child: Text(
                            _progression,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
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
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate again'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _regenerateProgression,
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Shuffle chords'),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Copy composition idea',
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
                        Text('Recent ideas', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._history.take(5).map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.music_note),
                            title: Text(item),
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
                    NavButton(label: 'Irony Generator 🥐', routeName: AppRoutes.ironyGenerator),
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
