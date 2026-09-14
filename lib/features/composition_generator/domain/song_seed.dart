/// Immutable song-seed values shared by Composition Studio and legacy UIs.
class SongSeed {
  const SongSeed({
    required this.tonicKey,
    required this.mode,
    required this.bpm,
    required this.timeSignature,
    required this.progression,
  });

  final String tonicKey;
  final String mode;
  final int bpm;
  final String timeSignature;
  final String progression;

  String get resultText =>
      'Key: $tonicKey $mode · BPM: $bpm · Time: $timeSignature · Progression: $progression';

  SongSeed copyWith({
    String? tonicKey,
    String? mode,
    int? bpm,
    String? timeSignature,
    String? progression,
  }) =>
      SongSeed(
        tonicKey: tonicKey ?? this.tonicKey,
        mode: mode ?? this.mode,
        bpm: bpm ?? this.bpm,
        timeSignature: timeSignature ?? this.timeSignature,
        progression: progression ?? this.progression,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongSeed &&
          tonicKey == other.tonicKey &&
          mode == other.mode &&
          bpm == other.bpm &&
          timeSignature == other.timeSignature &&
          progression == other.progression;

  @override
  int get hashCode =>
      Object.hash(tonicKey, mode, bpm, timeSignature, progression);
}
