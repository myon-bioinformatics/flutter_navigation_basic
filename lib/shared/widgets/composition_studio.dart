import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/composition_generator/domain/metronome_timing.dart';
import '../display/display_scope.dart';

class CompositionStudio extends StatefulWidget {
  const CompositionStudio({
    super.key,
    required this.initialBpm,
    required this.initialKey,
  });

  final int initialBpm;
  final String initialKey;

  @override
  State<CompositionStudio> createState() => _CompositionStudioState();
}

class _CompositionStudioState extends State<CompositionStudio>
    with SingleTickerProviderStateMixin {
  final Stopwatch _clock = Stopwatch();
  final Stopwatch _tapClock = Stopwatch();
  final TapTempoTracker _tapTempo = TapTempoTracker();
  final TextEditingController _lyricsController = TextEditingController();
  final TextEditingController _chordsController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  late final Ticker _ticker;
  late int _bpm;
  int _beatsPerBar = 4;
  int _beatUnit = 4;
  int _subdivisionsPerBeat = 2;
  bool _running = false;
  List<String> _sections = ['Intro', 'Verse', 'Chorus', 'Verse', 'Chorus', 'Outro'];

  @override
  void initState() {
    super.initState();
    _bpm = widget.initialBpm.clamp(
      MetronomeSnapshot.minBpm,
      MetronomeSnapshot.maxBpm,
    );
    _tapClock.start();
    _ticker = createTicker((_) {
      if (!mounted || !_running) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.stop();
    _tapClock.stop();
    _lyricsController.dispose();
    _chordsController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  MetronomeSnapshot get _snapshot => MetronomeSnapshot.fromElapsed(
        elapsed: _clock.elapsed,
        bpm: _bpm,
        beatsPerBar: _beatsPerBar,
        subdivisionsPerBeat: _subdivisionsPerBeat,
      );

  void _toggleMetronome() {
    setState(() {
      _running = !_running;
      if (_running) {
        _clock
          ..reset()
          ..start();
        _ticker.start();
      } else {
        _ticker.stop();
        _clock.stop();
      }
    });
  }

  void _tap() {
    final tempo = _tapTempo.addTap(_tapClock.elapsed);
    if (tempo == null) return;
    setState(() {
      _bpm = tempo;
      if (_running) _clock.reset();
    });
  }

  void _setSignature(String value) {
    final parts = value.split('/');
    setState(() {
      _beatsPerBar = int.parse(parts[0]);
      _beatUnit = int.parse(parts[1]);
      if (_running) _clock.reset();
    });
  }

  void _moveSection(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _sections.length) return;
    setState(() {
      final copy = [..._sections];
      final item = copy.removeAt(index);
      copy.insert(target, item);
      _sections = copy;
    });
  }

  void _addSection() {
    final value = _sectionController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _sections = [..._sections, value];
      _sectionController.clear();
    });
  }

  String _durationLabel(Duration duration) {
    final milliseconds = duration.inMicroseconds / 1000;
    if (milliseconds >= 1000) {
      return '${(milliseconds / 1000).toStringAsFixed(2)} s';
    }
    return '${milliseconds.round()} ms';
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final snapshot = _snapshot;
    final beatDuration = MetronomeSnapshot.beatUnitDuration(_bpm);
    final barDuration = MetronomeSnapshot.barDuration(_bpm, _beatsPerBar);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          display.text('compositionStudio.heading', arguments: {'key': widget.initialKey}),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(display.text('compositionStudio.subtitle')),
        const SizedBox(height: 16),
        _buildMetronomeCard(
          context,
          snapshot,
          beatDuration,
          barDuration,
          reduceMotion,
        ),
        const SizedBox(height: 16),
        _buildStructureCard(context),
        const SizedBox(height: 16),
        _buildWritingCard(context),
      ],
    );
  }

  Widget _buildMetronomeCard(
    BuildContext context,
    MetronomeSnapshot snapshot,
    Duration beatDuration,
    Duration barDuration,
    bool reduceMotion,
  ) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(display.text('compositionStudio.visualMetronome'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              display.text('compositionStudio.meterSummary', arguments: {
                'beatsPerBar': _beatsPerBar,
                'beatUnit': _beatUnit,
                'subdivisions': _subdivisionsPerBeat,
              }),
            ),
            if (_beatUnit == 8)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(display.text('compositionStudio.compoundMeterNote')),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      Text(display.text('compositionLegacy.bpm')),
                      Expanded(
                        child: Slider(
                          value: _bpm.toDouble(),
                          min: MetronomeSnapshot.minBpm.toDouble(),
                          max: MetronomeSnapshot.maxBpm.toDouble(),
                          divisions: MetronomeSnapshot.maxBpm - MetronomeSnapshot.minBpm,
                          label: '$_bpm',
                          onChanged: (value) => setState(() {
                            _bpm = value.round();
                            if (_running) _clock.reset();
                          }),
                        ),
                      ),
                      SizedBox(width: 40, child: Text('$_bpm')),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: '$_beatsPerBar/$_beatUnit',
                  items: const [
                    DropdownMenuItem(value: '3/4', child: Text('3/4')),
                    DropdownMenuItem(value: '4/4', child: Text('4/4')),
                    DropdownMenuItem(value: '6/8', child: Text('6/8')),
                  ],
                  onChanged: (value) {
                    if (value != null) _setSignature(value);
                  },
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1×')),
                    ButtonSegment(value: 2, label: Text('2×')),
                    ButtonSegment(value: 4, label: Text('4×')),
                  ],
                  selected: {_subdivisionsPerBeat},
                  onSelectionChanged: (value) => setState(() {
                    _subdivisionsPerBeat = value.first;
                    if (_running) _clock.reset();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _toggleMetronome,
                  icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                  label: Text(display.text(_running ? 'compositionStudio.stop' : 'compositionStudio.start')),
                ),
                OutlinedButton.icon(
                  onPressed: _tap,
                  icon: const Icon(Icons.touch_app_outlined),
                  label: Text(
                    _tapTempo.tapCount > 1
                        ? display.text('compositionStudio.tapTempoWithBpm', arguments: {'bpm': _bpm})
                        : display.text('compositionStudio.tapTempo'),
                  ),
                ),
                Text(display.text('compositionStudio.beatOf', arguments: {
                  'index': snapshot.beatIndex + 1,
                  'total': _beatsPerBar,
                })),
                Text(
                  display.text('compositionStudio.beatBarDuration', arguments: {
                    'beat': _durationLabel(beatDuration),
                    'bar': _durationLabel(barDuration),
                  }),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _beatsPerBar; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 90),
                      width: i == snapshot.beatIndex ? 28 : 20,
                      height: i == snapshot.beatIndex ? 28 : 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == snapshot.beatIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _beatDotMatrix(snapshot),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 14),
            Text(
              _subdivisionLine(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
            ),
            Text(
              _subdivisionMarker(snapshot),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < _beatsPerBar; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 80),
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == snapshot.beatIndex
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: snapshot.phase),
            const SizedBox(height: 8),
            Text(display.text('compositionStudio.stopwatchNote')),
          ],
        ),
      ),
    );
  }

  String _beatDotMatrix(MetronomeSnapshot snapshot) {
    return List.generate(
      _beatsPerBar,
      (i) => i == snapshot.beatIndex ? '●' : '○',
    ).join('  ');
  }

  String _subdivisionLine() {
    final tokens = <String>[];
    for (var beat = 1; beat <= _beatsPerBar; beat++) {
      tokens.add('$beat');
      if (_subdivisionsPerBeat == 2) {
        tokens.add('&');
      } else if (_subdivisionsPerBeat == 4) {
        tokens.addAll(['e', '&', 'a']);
      }
    }
    return '| ${tokens.join(' ')} |';
  }

  String _subdivisionMarker(MetronomeSnapshot snapshot) {
    final slot = snapshot.beatIndex * _subdivisionsPerBeat + snapshot.subdivisionIndex;
    return '${List.filled(slot * 2 + 2, ' ').join()}▲';
  }

  Widget _buildStructureCard(BuildContext context) {
    final display = DisplayScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(display.text('compositionStudio.songStructure'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(display.text('compositionStudio.songStructureSubtitle')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _sections.length; i++)
                  InputChip(
                    label: Text('${i + 1}. ${_sections[i]}'),
                    onDeleted: () => setState(() => _sections = [
                          ..._sections.take(i),
                          ..._sections.skip(i + 1),
                        ]),
                    avatar: PopupMenuButton<String>(
                      tooltip: display.text('compositionStudio.reorderTooltip', arguments: {'section': _sections[i]}),
                      icon: const Icon(Icons.swap_vert, size: 18),
                      onSelected: (value) =>
                          _moveSection(i, value == 'up' ? -1 : 1),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'up', child: Text(display.text('compositionStudio.moveUp'))),
                        PopupMenuItem(value: 'down', child: Text(display.text('compositionStudio.moveDown'))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sectionController,
                    decoration: InputDecoration(
                      labelText: display.text('compositionStudio.addSection'),
                      hintText: display.text('compositionStudio.addSectionHint'),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addSection(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addSection,
                  tooltip: display.text('compositionStudio.addSection'),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingCard(BuildContext context) {
    final display = DisplayScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final lyrics = _writingField(
              controller: _lyricsController,
              label: display.text('compositionStudio.lyricsLabel'),
              hint: 'Verse 1\n…\n\nChorus\n…',
            );
            final chords = _writingField(
              controller: _chordsController,
              label: display.text('compositionStudio.chordsLabel'),
              hint: '| C | Am | F | G |',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(display.text('compositionStudio.lyricsChordsHeading'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(display.text('compositionStudio.lyricsChordsSubtitle')),
                const SizedBox(height: 12),
                if (stacked) ...[
                  lyrics,
                  const SizedBox(height: 12),
                  chords,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: lyrics),
                      const SizedBox(width: 12),
                      Expanded(child: chords),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _writingField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      minLines: 8,
      maxLines: 16,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
