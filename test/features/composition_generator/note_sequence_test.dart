import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/composition_generator/domain/note_sequence.dart';

void main() {
  group('NoteSequence', () {
    test('parses and normalizes note tokens', () {
      expect(
        NoteSequence.parse('C3 d3 F#3 Gb3'),
        ['C3', 'D3', 'F♯3', 'G♭3'],
      );
    });

    test('splits eight eighth notes into one 4/4 bar', () {
      final bars = NoteSequence.bars(
        NoteSequence.parse('C3 D3 C3 D3 G3 A3 G3 C4'),
        beatsPerBar: 4,
        beatUnit: 4,
        noteUnit: 8,
      );
      expect(bars, [
        ['C3', 'D3', 'C3', 'D3', 'G3', 'A3', 'G3', 'C4'],
      ]);
    });

    test('splits quarter notes vertically by measure', () {
      final bars = NoteSequence.bars(
        NoteSequence.parse('C3 D3 E3 F3 G3 A3 B3 C4'),
        beatsPerBar: 4,
        beatUnit: 4,
        noteUnit: 4,
      );
      expect(bars, [
        ['C3', 'D3', 'E3', 'F3'],
        ['G3', 'A3', 'B3', 'C4'],
      ]);
    });

    test('supports six eighth notes per 6/8 bar', () {
      expect(
        NoteSequence.notesPerBar(beatsPerBar: 6, beatUnit: 8, noteUnit: 8),
        6,
      );
      expect(
        NoteSequence.notesPerBar(beatsPerBar: 6, beatUnit: 8, noteUnit: 4),
        3,
      );
    });

    test('rejects unsupported note syntax', () {
      expect(() => NoteSequence.parse('C3 nope D3'), throwsFormatException);
    });
  });
}
