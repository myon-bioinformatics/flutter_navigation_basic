import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/routes.dart';
import '../data/composer.dart';
import '../shared/display/display_scope.dart';
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

  void _recordCurrent() {
    _history.remove(_resultText);
    _history.insert(0, _resultText);
    if (_history.length > 6) _history.removeLast();
  }

  void _generate({bool initial = false}) {
    String key;
    String mode;
    int bpm;
    String timeSignature;
    String progression;
    var attempts = 0;

    do {
      key = Composer.diatonicScaleList[
          _random.nextInt(Composer.diatonicScaleList.length)];
      mode = Composer.modes[_random.nextInt(Composer.modes.length)];
      bpm = 80 + _random.nextInt(81);
      timeSignature = Composer.timeSignatures[
          _random.nextInt(Composer.timeSignatures.length)];
      final progressions = mode == 'Major'
          ? Composer.progressionsMajor
          : Composer.progressionsMinor;
      progression = progressions[_random.nextInt(progressions.length)];
      attempts++;
    } while (!initial &&
        attempts < 8 &&
        key == _tonicKey &&
        mode == _mode &&
        bpm == _bpm &&
        timeSignature == _timeSignature &&
        progression == _progression);

    void assign() {
      _tonicKey = key;
      _mode = mode;
      _bpm = bpm;
      _timeSignature = timeSignature;
      _progression = progression;
      _recordCurrent();
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
      var next = pool[_random.nextInt(pool.length)];
      if (pool.length > 1) {
        while (next == _progression) {
          next = pool[_random.nextInt(pool.length)];
        }
      }
      _progression = next;
      _recordCurrent();
    });
  }

  void _changeMode(String mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _progression = _progressionPool.first;
    });
  }

  void _saveCurrent() {
    setState(_recordCurrent);
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(display.text('compositionLegacy.savedSnackbar'))),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _resultText));
    if (!mounted) return;
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(display.text('compositionLegacy.copiedSnackbar'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('nav.compositionGenerator')),
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
                        Text(display.text('compositionLegacy.songSeed'), style: theme.textTheme.titleMedium),
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
                          child: ExcludeSemantics(
                            child: Text(
                              _progression,
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
                              icon: const Icon(Icons.auto_awesome),
                              label: Text(display.text('compositionLegacy.generateAgain')),
                            ),
                            OutlinedButton.icon(
                              onPressed: _regenerateProgression,
                              icon: const Icon(Icons.shuffle),
                              label: Text(display.text('compositionLegacy.shuffleChords')),
                            ),
                            OutlinedButton.icon(
                              onPressed: _saveCurrent,
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: Text(display.text('compositionLegacy.saveCurrent')),
                            ),
                            IconButton.filledTonal(
                              tooltip: display.text('compositionLegacy.copyTooltip'),
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
                  child: ExpansionTile(
                    title: Text(display.text('compositionLegacy.customizeSeed')),
                    subtitle: Text(display.text('compositionLegacy.customizeSeedSubtitle')),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final fieldWidth = width >= 560 ? (width - 12) / 2 : width;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: fieldWidth,
                                child: DropdownButtonFormField<String>(
                                  value: _tonicKey,
                                  isExpanded: true,
                                  decoration: InputDecoration(labelText: display.text('compositionLegacy.key')),
                                  items: Composer.diatonicScaleList
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _tonicKey = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: DropdownButtonFormField<String>(
                                  value: _mode,
                                  isExpanded: true,
                                  decoration: InputDecoration(labelText: display.text('compositionLegacy.mode')),
                                  items: Composer.modes
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) _changeMode(value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: DropdownButtonFormField<String>(
                                  value: _timeSignature,
                                  isExpanded: true,
                                  decoration: InputDecoration(labelText: display.text('compositionLegacy.timeSignature')),
                                  items: Composer.timeSignatures
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _timeSignature = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: DropdownButtonFormField<String>(
                                  value: _progression,
                                  isExpanded: true,
                                  decoration: InputDecoration(labelText: display.text('compositionLegacy.progression')),
                                  items: _progressionPool
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _progression = value);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(display.text('compositionLegacy.bpm')),
                          Expanded(
                            child: Slider(
                              min: 60,
                              max: 200,
                              divisions: 140,
                              label: '$_bpm',
                              value: _bpm.toDouble(),
                              onChanged: (value) => setState(() => _bpm = value.round()),
                            ),
                          ),
                          SizedBox(width: 44, child: Text('$_bpm')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(display.text('compositionLegacy.recentIdeas'), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._history.take(5).map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.music_note),
                            title: Text(
                              item,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(label: display.text('home.title'), routeName: AppRoutes.home),
                    NavButton(label: display.text('nav.counterPlayground'), routeName: AppRoutes.counterPlayground),
                    NavButton(label: display.text('nav.ironyGenerator'), routeName: AppRoutes.ironyGenerator),
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
