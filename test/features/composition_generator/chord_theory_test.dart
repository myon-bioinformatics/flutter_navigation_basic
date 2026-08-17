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
          'Imaj7 V7 ii7 viiø7 IVsus2 IVadd9 Vaug',
          minor: false,
        ),
        ['Cmaj7', 'G7', 'Dm7', 'Bm7♭5', 'Fsus2', 'Fadd9', 'Gaug'],
      );
    });

    test('builds requested chord quality labels', () {
      expect(ChordTheory.applyModifier('B', 'm7♭5'), 'Bm7♭5');
      expect(ChordTheory.applyModifier('C', 'sus2'), 'Csus2');
      expect(ChordTheory.applyModifier('C', 'sus4'), 'Csus4');
      expect(ChordTheory.applyModifier('F', 'add9'), 'Fadd9');
      expect(ChordTheory.applyModifier('F', 'add11'), 'Fadd11');
      expect(ChordTheory.applyModifier('D', 'dim'), 'Ddim');
      expect(ChordTheory.applyModifier('E', 'aug'), 'Eaug');
      expect(ChordTheory.applyModifier('G', '7'), 'G7');
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
