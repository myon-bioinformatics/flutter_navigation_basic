import 'dart:math';
import '../../../config.dart';

class CompositionGeneratorController {
  CompositionGeneratorController({Random? random})
      : _random = random ?? Random() {
    tonicKey = Composer.diatonicScaleList[
      _random.nextInt(Composer.diatonicScaleList.length)
    ];
    bpm = 100 + _random.nextInt(61);
  }

  final Random _random;
  late final String tonicKey;
  late final int bpm;

  String get displayText => 'Key: $tonicKey, BPM: $bpm';
}
