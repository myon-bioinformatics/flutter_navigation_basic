import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/composition_generator/domain/chord_theory.dart';

void main() {
  group('ChordTheory', () {
    test('converts I V vi IV in C major', () {
      expect(
        ChordTheory.convertProgression('C', 'I V vi IV', minor: false),
        ['C', 'G', 'Am', 'F'],
      );
    });

    test('converts the same progression after transposition', () {
      final key = ChordTheory.transposeKey('C', 2);
      expect(key, 'D');
      expect(
        ChordTheory.convertProgression(key, 'I V vi IV', minor: false),
        ['D', 'A', 'Bm', 'G'],
      );
    });

    test('supports descending semitone transposition', () {
      expect(ChordTheory.transposeKey('C', -1), 'B');
    });

    test('moves to circle-of-fifths neighbors', () {
      expect(ChordTheory.fifthNeighbor('C', clockwise: false), 'F');
      expect(ChordTheory.fifthNeighbor('C', clockwise: true), 'G');
      expect(ChordTheory.fifthNeighbor('D♭', clockwise: false), 'G♭');
      expect(ChordTheory.fifthNeighbor('D♭', clockwise: true), 'A♭');
    });

    test('preserves diatonic letter spelling for sharp keys', () {
      expect(
        ChordTheory.scale('F♯', minor: false),
        ['F♯', 'G♯', 'A♯', 'B', 'C♯', 'D♯', 'E♯'],
      );
    });

    test('understands common roman-numeral chord suffixes', () {
      expect(
        ChordTheory.convertProgression(
          'C',
          'I6 IV6 Imaj7 V7 ii7 viiø7 IVsus2 IVadd9 Vaug',
          minor: false,
        ),
        [
          'C6',
          'F6',
          'Cmaj7',
          'G7',
          'Dm7',
          'Bm7♭5',
          'Fsus2',
          'Fadd9',
          'Gaug',
        ],
      );
    });

    test('keeps diatonic minor quality when adding a sixth suffix', () {
      expect(
        ChordTheory.convertProgression('C', 'ii6 vi6', minor: false),
        ['Dm6', 'Am6'],
      );
    });

    test('builds requested chord quality labels', () {
      expect(ChordTheory.applyModifier('C', '6'), 'C6');
      expect(ChordTheory.applyModifier('C', 'm6'), 'Cm6');
      expect(ChordTheory.applyModifier('B', 'm7♭5'), 'Bm7♭5');
      expect(ChordTheory.applyModifier('C', 'sus2'), 'Csus2');
      expect(ChordTheory.applyModifier('C', 'sus4'), 'Csus4');
      expect(ChordTheory.applyModifier('F', 'add9'), 'Fadd9');
      expect(ChordTheory.applyModifier('F', 'add11'), 'Fadd11');
      expect(ChordTheory.applyModifier('D', 'dim'), 'Ddim');
      expect(ChordTheory.applyModifier('E', 'aug'), 'Eaug');
      expect(ChordTheory.applyModifier('G', '7'), 'G7');
    });

    test('exposes root through third inversion for four-note chords', () {
      expect(ChordTheory.chordWithInversion('C', 'maj7', 0), 'Cmaj7');
      expect(ChordTheory.chordWithInversion('C', 'maj7', 1), 'Cmaj7/E');
      expect(ChordTheory.chordWithInversion('C', 'maj7', 2), 'Cmaj7/G');
      expect(ChordTheory.chordWithInversion('C', 'maj7', 3), 'Cmaj7/B');
      expect(ChordTheory.chordWithInversion('C', '6', 3), 'C6/A');
    });

    test('loops triad third-inversion slot back to first inversion', () {
      expect(ChordTheory.normalizedInversion('triad', 3), 1);
      expect(ChordTheory.chordWithInversion('C', 'triad', 3), 'C/E');
      expect(ChordTheory.chordWithInversion('C', 'sus4', 3), 'Csus4/F');
    });

    test('major scale degrees expose diatonic chord qualities', () {
      expect(
        [
          for (var degree = 1; degree <= 7; degree++)
            ChordTheory.diatonicChord('C', degree, minor: false),
        ],
        ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
      );
    });
  });
}
