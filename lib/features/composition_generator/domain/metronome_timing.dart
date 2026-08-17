class MetronomeSnapshot {
  const MetronomeSnapshot({
    required this.beatIndex,
    required this.subdivisionIndex,
    required this.phase,
  });

  static const int minBpm = 30;
  static const int maxBpm = 300;

  final int beatIndex;
  final int subdivisionIndex;
  final double phase;

  static Duration beatUnitDuration(int bpm) {
    final safeBpm = bpm.clamp(minBpm, maxBpm);
    return Duration(microseconds: (60000000 / safeBpm).round());
  }

  static Duration subdivisionDuration(int bpm, int subdivisionsPerBeat) {
    if (subdivisionsPerBeat <= 0) {
      throw ArgumentError.value(
        subdivisionsPerBeat,
        'subdivisionsPerBeat',
        'must be positive',
      );
    }
    final beatMicros = beatUnitDuration(bpm).inMicroseconds;
    return Duration(
      microseconds: (beatMicros / subdivisionsPerBeat).round(),
    );
  }

  static Duration barDuration(int bpm, int beatsPerBar) {
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(beatsPerBar, 'beatsPerBar', 'must be positive');
    }
    return Duration(
      microseconds: beatUnitDuration(bpm).inMicroseconds * beatsPerBar,
    );
  }

  static MetronomeSnapshot fromElapsed({
    required Duration elapsed,
    required int bpm,
    required int beatsPerBar,
    required int subdivisionsPerBeat,
  }) {
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(beatsPerBar, 'beatsPerBar', 'must be positive');
    }
    if (subdivisionsPerBeat <= 0) {
      throw ArgumentError.value(
        subdivisionsPerBeat,
        'subdivisionsPerBeat',
        'must be positive',
      );
    }

    final subdivisionMicros =
        subdivisionDuration(bpm, subdivisionsPerBeat).inMicroseconds;
    final elapsedMicros = elapsed.inMicroseconds < 0 ? 0 : elapsed.inMicroseconds;
    final absoluteSubdivision = elapsedMicros ~/ subdivisionMicros;
    final beatIndex =
        (absoluteSubdivision ~/ subdivisionsPerBeat) % beatsPerBar;
    final subdivisionIndex = absoluteSubdivision % subdivisionsPerBeat;
    final remainder = elapsedMicros % subdivisionMicros;
    final phase = remainder / subdivisionMicros;

    return MetronomeSnapshot(
      beatIndex: beatIndex,
      subdivisionIndex: subdivisionIndex,
      phase: phase,
    );
  }
}

class TapTempoTracker {
  TapTempoTracker({
    this.resetGap = const Duration(seconds: 2),
    this.maxIntervals = 5,
  });

  final Duration resetGap;
  final int maxIntervals;
  final List<Duration> _taps = [];

  int get tapCount => _taps.length;

  void reset() => _taps.clear();

  int? addTap(Duration elapsed) {
    if (_taps.isNotEmpty && elapsed - _taps.last > resetGap) {
      _taps.clear();
    }
    _taps.add(elapsed);

    final maxTaps = maxIntervals + 1;
    if (_taps.length > maxTaps) {
      _taps.removeAt(0);
    }
    if (_taps.length < 2) return null;

    var totalMicros = 0;
    for (var i = 1; i < _taps.length; i++) {
      totalMicros += (_taps[i] - _taps[i - 1]).inMicroseconds;
    }
    final intervalCount = _taps.length - 1;
    final averageMicros = totalMicros / intervalCount;
    if (averageMicros <= 0) return null;

    final bpm = (60000000 / averageMicros).round();
    return bpm.clamp(MetronomeSnapshot.minBpm, MetronomeSnapshot.maxBpm);
  }
}
