import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/now_timeline/domain/now_timeline_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IanaTimeRules', () {
    test('Tokyo stays UTC+9 without DST', () {
      expect(
        IanaTimeRules.offsetMinutesAtUtc(
          'Asia/Tokyo',
          DateTime.utc(2026, 1, 15, 12),
        ),
        540,
      );
      expect(
        IanaTimeRules.offsetMinutesAtUtc(
          'Asia/Tokyo',
          DateTime.utc(2026, 7, 15, 12),
        ),
        540,
      );
      expect(
        IanaTimeRules.isDst('Asia/Tokyo', DateTime.utc(2026, 7, 15, 12)),
        isFalse,
      );
    });

    test('matches the Python zoneinfo oracle fixture from PR #30', () {
      final fixture = jsonDecode(
        File('tool/time/fixtures/timezone_cases.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final cases = fixture['cases'] as List<dynamic>;

      for (final raw in cases) {
        final item = (raw as Map).cast<String, dynamic>();
        final zone = item['zone'] as String;
        final utc = DateTime.parse(item['utc'] as String).toUtc();
        expect(
          IanaTimeRules.offsetMinutesAtUtc(zone, utc),
          item['offset_minutes'],
          reason: '$zone @ ${item['utc']}',
        );
        expect(
          IanaTimeRules.isDst(zone, utc),
          item['is_dst'],
          reason: '$zone @ ${item['utc']}',
        );
      }
    });

    test('wall time converts to UTC for ordinary times', () {
      final tokyo = IanaTimeRules.localWallTimeToUtc(
        'Asia/Tokyo',
        DateTime(2026, 8, 17, 20),
      );
      final london = IanaTimeRules.localWallTimeToUtc(
        'Europe/London',
        DateTime(2026, 8, 17, 12),
      );
      expect(tokyo, DateTime.utc(2026, 8, 17, 11));
      expect(london, DateTime.utc(2026, 8, 17, 11));
    });

    test('rejects a non-existent spring-forward wall time', () {
      expect(
        () => IanaTimeRules.localWallTimeToUtc(
          'Europe/London',
          DateTime(2026, 3, 29, 1, 30),
        ),
        throwsFormatException,
      );
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
