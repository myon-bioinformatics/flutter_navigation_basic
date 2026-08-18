import 'package:flutter/material.dart';

import '../../features/composition_generator/domain/note_sequence.dart';
import '../display/display_scope.dart';

class NoteSequenceCard extends StatefulWidget {
  const NoteSequenceCard({super.key});

  @override
  State<NoteSequenceCard> createState() => _NoteSequenceCardState();
}

class _NoteSequenceCardState extends State<NoteSequenceCard> {
  final TextEditingController _controller = TextEditingController(
    text: 'C3 D3 C3 D3 G3 A3 G3 C4',
  );
  int _beatsPerBar = 4;
  int _beatUnit = 4;
  int _noteUnit = 8;
  String? _error;
  Set<int> _expandedBars = {0};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<List<String>> _bars() {
    try {
      final notes = NoteSequence.parse(_controller.text);
      _error = null;
      return NoteSequence.bars(
        notes,
        beatsPerBar: _beatsPerBar,
        beatUnit: _beatUnit,
        noteUnit: _noteUnit,
      );
    } on FormatException catch (error) {
      _error = error.message;
      return const [];
    } on ArgumentError catch (error) {
      _error = error.message?.toString() ?? 'Invalid sequence';
      return const [];
    }
  }

  void _setSignature(String value) {
    final parts = value.split('/');
    setState(() {
      _beatsPerBar = int.parse(parts[0]);
      _beatUnit = int.parse(parts[1]);
      _expandedBars = {0};
    });
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars();
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(display.text('noteSequence.title'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(display.text('noteSequence.subtitle')),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: display.text('noteSequence.sequenceLabel'),
                hintText: 'C3 D3 C3 D3 G3 A3 G3 C4',
                border: const OutlineInputBorder(),
                helperText: display.text('noteSequence.helperText'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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
                  segments: [
                    ButtonSegment(value: 4, label: Text(display.text('noteSequence.quarterNote'))),
                    ButtonSegment(value: 8, label: Text(display.text('noteSequence.eighthNote'))),
                  ],
                  selected: {_noteUnit},
                  onSelectionChanged: (value) => setState(() {
                    _noteUnit = value.first;
                    _expandedBars = {0};
                  }),
                ),
                Text(display.text(
                  bars.length == 1 ? 'noteSequence.barCountSingular' : 'noteSequence.barCountPlural',
                  arguments: {'meter': '$_beatsPerBar/$_beatUnit', 'count': bars.length},
                )),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 14),
            if (bars.isEmpty && _error == null)
              Text(display.text('noteSequence.emptyPrompt'))
            else
              ...[
                for (var index = 0; index < bars.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      key: ValueKey(
                        'sequence-bar-$index-$_noteUnit-$_beatsPerBar-$_beatUnit',
                      ),
                      initiallyExpanded: _expandedBars.contains(index),
                      onExpansionChanged: (expanded) => setState(() {
                        if (expanded) {
                          _expandedBars = {..._expandedBars, index};
                        } else {
                          _expandedBars = {..._expandedBars}..remove(index);
                        }
                      }),
                      title: Text(display.text('noteSequence.barTitle', arguments: {'n': index + 1})),
                      subtitle: Text(bars[index].join('  ')),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var event = 0; event < bars[index].length; event++)
                                Chip(
                                  avatar: CircleAvatar(child: Text('${event + 1}')),
                                  label: Text('${bars[index][event]} · 1/$_noteUnit'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            const SizedBox(height: 4),
            Text(display.text('noteSequence.sketchOnlyNote')),
          ],
        ),
      ),
    );
  }
}
