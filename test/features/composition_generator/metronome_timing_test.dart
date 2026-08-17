import 'package:flutter_application_1/features/composition_generator/domain/metronome_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetronomeSnapshot', () {
    test('calculates beat and bar durations from BPM', () {
      expect(
        MetronomeSnapshot.beatUnitDuration(120),
        const Duration(milliseconds: 500),
      );
      expect(
        MetronomeSnapshot.barDuration(120, 4),
        const Duration(seconds: 2),
      );
      expect(
        MetronomeSnapshot.subdivisionDuration(120, 2),
        const Duration(milliseconds: 250),
      );
    });

    test('derives musical position from elapsed time rather than frame count', () {
      final snapshot = MetronomeSnapshot.fromElapsed(
        elapsed: const Duration(milliseconds: 750),
        bpm: 120,
        beatsPerBar: 4,
        subdivisionsPerBeat: 2,
      );

      expect(snapshot.beatIndex, 1);
      expect(snapshot.subdivisionIndex, 1);
      expect(snapshot.phase, closeTo(0, 0.0001));
    });

    test('wraps beat position at the end of a bar', () {
      final snapshot = MetronomeSnapshot.fromElapsed(
        elapsed: const Duration(milliseconds: 2250),
        bpm: 120,
        beatsPerBar: 4,
        subdivisionsPerBeat: 2,
      );

      expect(snapshot.beatIndex, 0);
      expect(snapshot.subdivisionIndex, 1);
    });
  });

  group('TapTempoTracker', () {
    test('averages deterministic tap intervals', () {
      final tracker = TapTempoTracker();

      expect(tracker.addTap(Duration.zero), isNull);
      expect(tracker.addTap(const Duration(milliseconds: 500)), 120);
      expect(tracker.addTap(const Duration(milliseconds: 1000)), 120);
      expect(tracker.addTap(const Duration(milliseconds: 1500)), 120);
    });

    test('resets after a long gap', () {
      final tracker = TapTempoTracker();

      tracker.addTap(Duration.zero);
      expect(tracker.addTap(const Duration(milliseconds: 500)), 120);
      expect(tracker.addTap(const Duration(seconds: 3)), isNull);
      expect(tracker.tapCount, 1);
    });

    test('clamps extreme tap tempo to supported BPM range', () {
      final tracker = TapTempoTracker();

      tracker.addTap(Duration.zero);
      expect(tracker.addTap(const Duration(milliseconds: 100)), 300);
    });
  });
}
