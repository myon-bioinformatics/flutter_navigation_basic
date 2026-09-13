import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/composer.dart';
import '../../features/composition_generator/domain/song_seed.dart';
import '../../features/composition_generator/domain/song_seed_generator.dart';
import '../display/display_scope.dart';

/// Expandable Song Seed controls shared by Composition Studio and legacy UIs.
class SongSeedPanel extends StatefulWidget {
  const SongSeedPanel({
    super.key,
    this.onApply,
    this.initiallyExpanded = false,
    this.generator,
  });

  /// When set, shows an Apply action that pushes the seed into the host studio.
  final ValueChanged<SongSeed>? onApply;

  final bool initiallyExpanded;

  final SongSeedGenerator? generator;

  @override
  State<SongSeedPanel> createState() => _SongSeedPanelState();
}

class _SongSeedPanelState extends State<SongSeedPanel> {
  late final SongSeedGenerator _generator;
  late SongSeed _seed;
  final List<String> _history = <String>[];

  @override
  void initState() {
    super.initState();
    _generator = widget.generator ?? SongSeedGenerator();
    _seed = _generator.generate();
    _recordCurrent();
  }

  List<String> get _progressionPool =>
      _generator.progressionPoolFor(_seed.mode);

  void _recordCurrent() {
    final text = _seed.resultText;
    _history.remove(text);
    _history.insert(0, text);
    if (_history.length > 6) {
      _history.removeLast();
    }
  }

  void _generate() {
    setState(() {
      _seed = _generator.generate(avoid: _seed);
      _recordCurrent();
    });
  }

  void _regenerateProgression() {
    setState(() {
      _seed = _generator.regenerateProgression(_seed);
      _recordCurrent();
    });
  }

  void _changeMode(String mode) {
    setState(() => _seed = _generator.changeMode(_seed, mode));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _seed.resultText));
    if (!mounted) return;
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(display.text('compositionLegacy.copiedSnackbar'))),
    );
  }

  void _saveCurrent() {
    setState(_recordCurrent);
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(display.text('compositionLegacy.savedSnackbar'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        title: Text(display.text('compositionStudio.songSeedGenerator')),
        subtitle: Text(display.text('compositionStudio.songSeedSectionSubtitle')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${_seed.tonicKey} ${_seed.mode}')),
              Chip(label: Text('${_seed.bpm} BPM')),
              Chip(label: Text(_seed.timeSignature)),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            label: 'Chord progression ${_seed.progression}',
            child: ExcludeSemantics(
              child: Text(
                _seed.progression,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
              if (widget.onApply != null)
                FilledButton.tonalIcon(
                  onPressed: () {
                    widget.onApply!(_seed);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(display.text('compositionStudio.seedApplied')),
                      ),
                    );
                  },
                  icon: const Icon(Icons.playlist_add_check),
                  label: Text(display.text('compositionStudio.applySeed')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(display.text('compositionLegacy.customizeSeed')),
            subtitle:
                Text(display.text('compositionLegacy.customizeSeedSubtitle')),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final fieldWidth =
                      width >= 560 ? (width - 12) / 2 : width;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          value: _seed.tonicKey,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: display.text('compositionLegacy.key'),
                          ),
                          items: Composer.diatonicScaleList
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(
                                () => _seed = _seed.copyWith(tonicKey: value),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          value: _seed.mode,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: display.text('compositionLegacy.mode'),
                          ),
                          items: Composer.modes
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _changeMode(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          value: _seed.timeSignature,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: display.text(
                              'compositionLegacy.timeSignature',
                            ),
                          ),
                          items: Composer.timeSignatures
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(
                                () => _seed =
                                    _seed.copyWith(timeSignature: value),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          value: _seed.progression,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText:
                                display.text('compositionLegacy.progression'),
                          ),
                          items: _progressionPool
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(
                                () => _seed =
                                    _seed.copyWith(progression: value),
                              );
                            }
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
                      label: '${_seed.bpm}',
                      value: _seed.bpm.toDouble(),
                      onChanged: (value) => setState(
                        () => _seed = _seed.copyWith(bpm: value.round()),
                      ),
                    ),
                  ),
                  SizedBox(width: 44, child: Text('${_seed.bpm}')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              display.text('compositionLegacy.recentIdeas'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }
}
