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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ChordTheory.scale(_key, minor: _minor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Key / Chord Translator', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Choose a key, transpose it, and turn Roman-numeral progressions such as I V vi IV into concrete chord names.',
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
                hintText: 'I V vi IV',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _progression = value),
            ),
            const SizedBox(height: 10),
            SelectableText(
              _converted.join('  ·  '),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),
            Text('Chord builder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Use a scale degree as the root, then attach common colors/extensions without adding a music-theory package.',
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
                      if (value != null) setState(() => _modifier = value);
                    },
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.music_note, size: 18),
                  label: Text(
                    ChordTheory.applyModifier(_builderRoot, _modifier),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Supported labels: 7, maj7, m7, m7♭5, sus2, sus4, add9, add11, dim, aug. “aug” is the standard abbreviation for augmented.',
            ),
          ],
        ),
      ),
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
