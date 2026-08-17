import 'package:flutter/material.dart';

import '../../features/composition_generator/domain/chord_theory.dart';

class ChordTheoryCard extends StatefulWidget {
  const ChordTheoryCard({super.key, required this.initialKey});

  final String initialKey;

  @override
  State<ChordTheoryCard> createState() => _ChordTheoryCardState();
}

class _ChordTheoryCardState extends State<ChordTheoryCard> {
  late final TextEditingController _progressionController;
  late String _key;
  bool _minor = false;
  String _progression = 'I V vi IV';
  int _builderDegree = 1;
  String _modifier = 'triad';
  int _inversion = 0;

  @override
  void initState() {
    super.initState();
    _key = ChordTheory.selectableKeys.contains(widget.initialKey)
        ? widget.initialKey
        : 'C';
    _progressionController = TextEditingController(text: _progression);
  }

  @override
  void dispose() {
    _progressionController.dispose();
    super.dispose();
  }

  List<String> get _converted => ChordTheory.convertProgression(
        _key,
        _progression,
        minor: _minor,
      );

  String get _builderRoot {
    final scale = ChordTheory.scale(_key, minor: _minor);
    return scale[_builderDegree - 1];
  }

  void _transpose(int semitones) {
    setState(() => _key = ChordTheory.transposeKey(_key, semitones));
  }

  void _moveByFifth(bool clockwise) {
    setState(() {
      _key = ChordTheory.fifthNeighbor(_key, clockwise: clockwise);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ChordTheory.scale(_key, minor: _minor);
    final leftFifth = ChordTheory.fifthNeighbor(_key, clockwise: false);
    final rightFifth = ChordTheory.fifthNeighbor(_key, clockwise: true);
    final normalizedInversion =
        ChordTheory.normalizedInversion(_modifier, _inversion);
    final inversionName = switch (normalizedInversion) {
      0 => 'Root position',
      1 => '1st inversion',
      2 => '2nd inversion',
      3 => '3rd inversion',
      _ => 'Root position',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Key / Chord Translator', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Choose a key, move by semitone or fifth, and turn Roman-numeral progressions into concrete chord names.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _key,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      border: OutlineInputBorder(),
                    ),
                    items: ChordTheory.selectableKeys
                        .map(
                          (key) => DropdownMenuItem(
                            value: key,
                            child: Text(key),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _key = value);
                    },
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Major')),
                    ButtonSegment(value: true, label: Text('Minor')),
                  ],
                  selected: {_minor},
                  onSelectionChanged: (value) =>
                      setState(() => _minor = value.first),
                ),
                OutlinedButton.icon(
                  onPressed: () => _transpose(-1),
                  icon: const Icon(Icons.remove),
                  label: const Text('−1 semitone'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _transpose(1),
                  icon: const Icon(Icons.add),
                  label: const Text('+1 semitone'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Circle-of-fifths neighbors', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _moveByFifth(false),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(leftFifth),
                ),
                Chip(
                  avatar: const Icon(Icons.radio_button_checked, size: 18),
                  label: Text(_key, style: theme.textTheme.titleMedium),
                ),
                OutlinedButton.icon(
                  onPressed: () => _moveByFifth(true),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(rightFifth),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Example in C: ← F   C   G →',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text('Scale degrees', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 1; i <= 7; i++)
                  Chip(
                    label: Text(
                      '${_roman(i, minor: _minor)} = ${ChordTheory.diatonicChord(_key, i, minor: _minor)}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _progressionController,
              decoration: const InputDecoration(
                labelText: 'Roman-numeral progression',
                hintText: 'I V vi IV · I6 IV6 · V7',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _progression = value),
            ),
            const SizedBox(height: 10),
            SelectableText(
              _converted.join('  ·  '),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildMeasureLayout(context),
            const SizedBox(height: 6),
            const Text(
              'The progression is wrapped into small measure blocks instead of a DAW-style endless horizontal timeline, so it stays usable on phones.',
            ),
            const SizedBox(height: 6),
            const Text(
              'In this lightweight translator, a suffix such as I6 means an added-sixth chord (C6 in C major), not figured-bass first-inversion notation.',
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),
            Text('Chord builder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Choose a scale-degree root, color/extension and inversion. Seventh/add-sixth chords expose a real third inversion; triads loop the third slot back to first inversion.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    value: _builderDegree,
                    decoration: const InputDecoration(
                      labelText: 'Degree / root',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (var i = 1; i <= 7; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${_roman(i, minor: _minor)} · ${scale[i - 1]}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _builderDegree = value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _modifier,
                    decoration: const InputDecoration(
                      labelText: 'Quality / extension',
                      border: OutlineInputBorder(),
                    ),
                    items: ChordTheory.chordModifiers
                        .map(
                          (modifier) => DropdownMenuItem(
                            value: modifier,
                            child: Text(
                              modifier == 'triad'
                                  ? 'triad / plain'
                                  : modifier,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _modifier = value;
                          if (_inversion > 3) _inversion = 0;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Root')),
                  ButtonSegment(value: 1, label: Text('1st')),
                  ButtonSegment(value: 2, label: Text('2nd')),
                  ButtonSegment(value: 3, label: Text('3rd')),
                ],
                selected: {_inversion},
                onSelectionChanged: (value) =>
                    setState(() => _inversion = value.first),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.music_note, size: 18),
                  label: Text(
                    ChordTheory.chordWithInversion(
                      _builderRoot,
                      _modifier,
                      _inversion,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(inversionName),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Supported labels: 6, m6, 7, maj7, m7, m7♭5, sus2, sus4, add9, add11, dim, aug. “aug” is the standard abbreviation for augmented.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420
            ? 2
            : constraints.maxWidth < 760
                ? 4
                : 8;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < _converted.length; i++)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('${i + 1}', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _converted[i],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _roman(int degree, {required bool minor}) {
    const upper = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
    const majorCase = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'];
    const minorCase = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII'];
    if (degree < 1 || degree > 7) return upper.first;
    return (minor ? minorCase : majorCase)[degree - 1];
  }
}
