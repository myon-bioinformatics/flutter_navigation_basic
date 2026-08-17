import 'package:flutter/material.dart';

import '../../features/composition_generator/domain/note_sequence.dart';

class NoteSequenceCard extends StatefulWidget {
  const NoteSequenceCard({
    super.key,
    required this.beatsPerBar,
    required this.beatUnit,
  });

  final int beatsPerBar;
  final int beatUnit;

  @override
  State<NoteSequenceCard> createState() => _NoteSequenceCardState();
}

class _NoteSequenceCardState extends State<NoteSequenceCard> {
  final TextEditingController _controller = TextEditingController(
    text: 'C3 D3 C3 D3 G3 A3 G3 C4',
  );
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
        beatsPerBar: widget.beatsPerBar,
        beatUnit: widget.beatUnit,
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

  @override
  Widget build(BuildContext context) {
    final bars = _bars();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pocket Sequence', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'A deliberately small monophonic sketchpad: type note names, choose quarter or eighth notes, and inspect the phrase bar by bar.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Monophonic note sequence',
                hintText: 'C3 D3 C3 D3 G3 A3 G3 C4',
                border: OutlineInputBorder(),
                helperText: 'Notes only; spaces or commas separate events. #/♯ and b/♭ are accepted.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 4, label: Text('1/4 note')),
                    ButtonSegment(value: 8, label: Text('1/8 note')),
                  ],
                  selected: {_noteUnit},
                  onSelectionChanged: (value) => setState(() {
                    _noteUnit = value.first;
                    _expandedBars = {0};
                  }),
                ),
                Text('${widget.beatsPerBar}/${widget.beatUnit} · ${bars.length} bar${bars.length == 1 ? '' : 's'}'),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            if (bars.isEmpty && _error == null)
              const Text('Enter notes to create the sequence.')
            else
              ...[
                for (var index = 0; index < bars.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      key: ValueKey('sequence-bar-$index-${_noteUnit}-${widget.beatsPerBar}-${widget.beatUnit}'),
                      initiallyExpanded: _expandedBars.contains(index),
                      onExpansionChanged: (expanded) => setState(() {
                        if (expanded) {
                          _expandedBars = {..._expandedBars, index};
                        } else {
                          _expandedBars = {..._expandedBars}..remove(index);
                        }
                      }),
                      title: Text('Bar ${index + 1}'),
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
            const Text(
              'This is a sketch sequencer, not audio/MIDI playback. The same bar model can later feed a richer horizontal timeline on large screens without changing the sequence data.',
            ),
          ],
        ),
      ),
    );
  }
}
