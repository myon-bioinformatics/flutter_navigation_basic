import 'package:flutter_application_1/features/now_timeline/domain/now_timeline_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IanaTimeRules', () {
    test('Tokyo stays UTC+9 without DST', () {
      expect(IanaTimeRules.offsetMinutesAtUtc('Asia/Tokyo', DateTime.utc(2026, 1, 15, 12)), 540);
      expect(IanaTimeRules.offsetMinutesAtUtc('Asia/Tokyo', DateTime.utc(2026, 7, 15, 12)), 540);
      expect(IanaTimeRules.isDst('Asia/Tokyo', DateTime.utc(2026, 7, 15, 12)), isFalse);
    });

    test('London crosses 2026 DST boundaries', () {
      expect(IanaTimeRules.offsetMinutesAtUtc('Europe/London', DateTime.utc(2026, 3, 29, 0, 59)), 0);
      expect(IanaTimeRules.offsetMinutesAtUtc('Europe/London', DateTime.utc(2026, 3, 29, 1, 1)), 60);
      expect(IanaTimeRules.offsetMinutesAtUtc('Europe/London', DateTime.utc(2026, 10, 25, 0, 59)), 60);
      expect(IanaTimeRules.offsetMinutesAtUtc('Europe/London', DateTime.utc(2026, 10, 25, 1, 1)), 0);
    });

    test('New York crosses 2026 DST boundaries', () {
      expect(IanaTimeRules.offsetMinutesAtUtc('America/New_York', DateTime.utc(2026, 3, 8, 6, 59)), -300);
      expect(IanaTimeRules.offsetMinutesAtUtc('America/New_York', DateTime.utc(2026, 3, 8, 7, 1)), -240);
      expect(IanaTimeRules.offsetMinutesAtUtc('America/New_York', DateTime.utc(2026, 11, 1, 5, 59)), -240);
      expect(IanaTimeRules.offsetMinutesAtUtc('America/New_York', DateTime.utc(2026, 11, 1, 6, 1)), -300);
    });

    test('wall time converts to UTC for ordinary times', () {
      final tokyo = IanaTimeRules.localWallTimeToUtc('Asia/Tokyo', DateTime(2026, 8, 17, 20, 0));
      final london = IanaTimeRules.localWallTimeToUtc('Europe/London', DateTime(2026, 8, 17, 12, 0));
      expect(tokyo, DateTime.utc(2026, 8, 17, 11, 0));
      expect(london, DateTime.utc(2026, 8, 17, 11, 0));
    });
  });

  test('TimelineEntry JSON round trip preserves client-side data', () {
    const entry = TimelineEntry(
      id: 'x',
      title: 'Dentist',
      kind: TimelineKind.schedule,
      zoneName: 'Asia/Tokyo',
      localStartMinute: 540,
      localEndMinute: 1110,
      note: 'Tue',
    );
    final restored = TimelineEntry.fromJson(entry.toJson());
    expect(restored.id, entry.id);
    expect(restored.kind, entry.kind);
    expect(restored.zoneName, entry.zoneName);
    expect(restored.localStartMinute, 540);
    expect(restored.localEndMinute, 1110);
  });
}
