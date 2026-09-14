import 'dart:math';

import '../../../data/composer.dart';
import 'song_seed.dart';

/// Pure song-seed generation (no Flutter imports).
class SongSeedGenerator {
  SongSeedGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<String> progressionPoolFor(String mode) =>
      mode == 'Major' ? Composer.progressionsMajor : Composer.progressionsMinor;

  SongSeed generate({SongSeed? avoid}) {
    SongSeed next;
    var attempts = 0;
    do {
      final mode = Composer.modes[_random.nextInt(Composer.modes.length)];
      final progressions = progressionPoolFor(mode);
      next = SongSeed(
        tonicKey: Composer.diatonicScaleList[
            _random.nextInt(Composer.diatonicScaleList.length)],
        mode: mode,
        bpm: 80 + _random.nextInt(81),
        timeSignature: Composer.timeSignatures[
            _random.nextInt(Composer.timeSignatures.length)],
        progression: progressions[_random.nextInt(progressions.length)],
      );
      attempts++;
    } while (avoid != null && attempts < 8 && next == avoid);
    return next;
  }

  SongSeed regenerateProgression(SongSeed current) {
    final pool = progressionPoolFor(current.mode);
    if (pool.isEmpty) return current;
    var next = pool[_random.nextInt(pool.length)];
    if (pool.length > 1) {
      while (next == current.progression) {
        next = pool[_random.nextInt(pool.length)];
      }
    }
    return current.copyWith(progression: next);
  }

  SongSeed changeMode(SongSeed current, String mode) {
    if (mode == current.mode) return current;
    final pool = progressionPoolFor(mode);
    return current.copyWith(
      mode: mode,
      progression: pool.isEmpty ? current.progression : pool.first,
    );
  }
}
