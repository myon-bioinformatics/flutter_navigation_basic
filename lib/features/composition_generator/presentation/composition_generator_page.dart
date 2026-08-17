import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../domain/composition_generator_controller.dart';
import '../domain/metronome_timing.dart';

class CompositionGeneratorPage extends StatefulWidget {
  const CompositionGeneratorPage({super.key, required this.controller});

  final CompositionGeneratorController controller;

  @override
  State<CompositionGeneratorPage> createState() => _CompositionGeneratorPageState();
}

class _CompositionGeneratorPageState extends State<CompositionGeneratorPage>
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
    _bpm = widget.controller.bpm.clamp(
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
    final snapshot = _snapshot;
    final beatDuration = MetronomeSnapshot.beatUnitDuration(_bpm);
    final barDuration = MetronomeSnapshot.barDuration(_bpm, _beatsPerBar);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Composition Studio 🎸'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lightweight songwriting support · ${widget.controller.tonicKey}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'A pre-DAW workspace: keep tempo, form, lyrics and chords together without turning this app into a full audio workstation.',
                ),
                const SizedBox(height: 20),
                _buildMetronomeCard(context, snapshot, beatDuration, barDuration, reduceMotion),
                const SizedBox(height: 16),
                _buildStructureCard(context),
                const SizedBox(height: 16),
                _buildWritingCard(context),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomButton(label: 'Home 🏠', onPressed: AppNavigation.toHome),
                    CustomButton(
                      label: 'Counter Playground 👾',
                      onPressed: AppNavigation.toCounterPlayground,
                    ),
                    CustomButton(
                      label: 'Irony Generator 🥐',
                      onPressed: AppNavigation.toIronyGenerator,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Visual Metronome', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '$_beatsPerBar/$_beatUnit · BPM counts the $_beatUnit-note beat unit · ${_subdivisionsPerBeat}× subdivision',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      const Text('BPM'),
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
                      SizedBox(width: 38, child: Text('$_bpm')),
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
                  label: Text(_running ? 'Stop' : 'Start'),
                ),
                OutlinedButton.icon(
                  onPressed: _tap,
                  icon: const Icon(Icons.touch_app_outlined),
                  label: Text('Tap Tempo${_tapTempo.tapCount > 1 ? ' · $_bpm BPM' : ''}'),
                ),
                Text('Beat ${snapshot.beatIndex + 1}/$_beatsPerBar'),
                Text('Beat ${_durationLabel(beatDuration)} · Bar ${_durationLabel(barDuration)}'),
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
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
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
            const SizedBox(height: 16),
            Text(
              _subdivisionLine(snapshot),
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
                for (var i = 0; i < _beatsPerBar; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 80),
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
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: snapshot.phase),
            const SizedBox(height: 8),
            const Text(
              'The Stopwatch is the timing source; Ticker only requests redraws. No audio backend or extra package is used in Stage 1.',
            ),
          ],
        ),
      ),
    );
  }

  String _subdivisionLine(MetronomeSnapshot snapshot) {
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
    final slotsPerBeat = _subdivisionsPerBeat;
    final currentSlot = snapshot.beatIndex * slotsPerBeat + snapshot.subdivisionIndex;
    final prefix = List.filled(currentSlot * 2 + 2, ' ').join();
    return '$prefix▲';
  }

  Widget _buildStructureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Song Structure', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Keep form editable in-place instead of opening another screen.'),
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
                      tooltip: 'Reorder ${_sections[i]}',
                      icon: const Icon(Icons.swap_vert, size: 18),
                      onSelected: (value) => _moveSection(i, value == 'up' ? -1 : 1),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'up', child: Text('Move up')),
                        PopupMenuItem(value: 'down', child: Text('Move down')),
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
                    decoration: const InputDecoration(
                      labelText: 'Add section',
                      hintText: 'Bridge, Pre-Chorus, Solo…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addSection(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addSection,
                  tooltip: 'Add section',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final lyrics = _writingField(
              controller: _lyricsController,
              label: 'Lyrics',
              hint: 'Verse 1\n…\n\nChorus\n…',
            );
            final chords = _writingField(
              controller: _chordsController,
              label: 'Chords',
              hint: '| C | Am | F | G |',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Lyrics / Chords', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('A session-local writing surface for ideas that are not ready for a DAW yet.'),
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
