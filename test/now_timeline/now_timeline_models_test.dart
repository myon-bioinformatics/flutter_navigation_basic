import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/now_timeline/domain/now_timeline_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('projectScheduleBoundaries', () {
    test('projects an overnight schedule end onto the following day', () {
      final boundaries = projectScheduleBoundaries(
        zoneName: 'Asia/Tokyo',
        localStartMinute: 22 * 60,
        localEndMinute: 2 * 60,
        localDay: DateTime(2026, 8, 17),
      );

      expect(boundaries, hasLength(2));
      expect(boundaries[0].isStart, isTrue);
      expect(boundaries[0].instantUtc, DateTime.utc(2026, 8, 17, 13));
      expect(boundaries[1].isStart, isFalse);
      expect(boundaries[1].instantUtc, DateTime.utc(2026, 8, 17, 17));
      expect(
        boundaries[1].instantUtc.isAfter(boundaries[0].instantUtc),
        isTrue,
      );
    });

    test('keeps a same-day schedule on the same local day', () {
      final boundaries = projectScheduleBoundaries(
        zoneName: 'Asia/Tokyo',
        localStartMinute: 9 * 60,
        localEndMinute: 17 * 60,
        localDay: DateTime(2026, 8, 17),
      );

      expect(boundaries, hasLength(2));
      expect(boundaries[0].instantUtc, DateTime.utc(2026, 8, 17, 0));
      expect(boundaries[1].instantUtc, DateTime.utc(2026, 8, 17, 8));
    });

    test(
      'skips a DST spring-forward gap boundary instead of throwing',
      () {
        // Europe/London clocks jump from 00:59 to 02:00 on 2026-03-29, so
        // a saved 01:30 start never occurs on that date.
        final boundaries = projectScheduleBoundaries(
          zoneName: 'Europe/London',
          localStartMinute: 1 * 60 + 30,
          localEndMinute: 10 * 60,
          localDay: DateTime(2026, 3, 29),
        );

        expect(boundaries, hasLength(1));
        expect(boundaries.single.isStart, isFalse);
        expect(boundaries.single.instantUtc, DateTime.utc(2026, 3, 29, 9));
      },
    );

    test('returns no boundaries when both start and end fall in the gap', () {
      final boundaries = projectScheduleBoundaries(
        zoneName: 'Europe/London',
        localStartMinute: 1 * 60 + 10,
        localEndMinute: 1 * 60 + 45,
        localDay: DateTime(2026, 3, 29),
      );

      expect(boundaries, isEmpty);
    });
  });

  group('NowTimelineStore write serialization', () {
    test('saveEntries persists calls in call order so the latest wins', () async {
      SharedPreferences.setMockInitialValues({});
      final store = NowTimelineStore();
      const first = [
        TimelineEntry(
          id: '1',
          title: 'First',
          kind: TimelineKind.person,
          zoneName: 'Asia/Tokyo',
        ),
      ];
      const second = [
        TimelineEntry(
          id: '1',
          title: 'Second',
          kind: TimelineKind.person,
          zoneName: 'Asia/Tokyo',
        ),
      ];

      final saveFirst = store.saveEntries(first);
      final saveSecond = store.saveEntries(second);
      await Future.wait([saveFirst, saveSecond]);

      final loaded = await store.loadEntries();
      expect(loaded.single.title, 'Second');
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
