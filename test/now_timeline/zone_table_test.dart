import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/now_timeline/domain/now_timeline_models.dart';
import 'package:flutter_application_1/features/now_timeline/domain/zone_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('assets/time/zone_table.json').readAsStringSync();
  final table = ZoneTable.fromJson(source);

  test('supported zones remain the existing three', () {
    expect(IanaTimeRules.supportedZones, [
      'Asia/Tokyo',
      'Europe/London',
      'America/New_York',
    ]);
    for (final zone in IanaTimeRules.supportedZones) {
      expect(table.containsZone(zone), isTrue);
    }
  });

  test('clamps outside both ends of the half-open window', () {
    final start = DateTime.utc(2000);
    final end = DateTime.utc(2038);
    for (final zone in IanaTimeRules.supportedZones) {
      final first = table.lookupAtUtc(zone, start);
      final before = table.lookupAtUtc(
        zone,
        start.subtract(const Duration(microseconds: 1)),
      );
      final last = table.lookupAtUtc(
        zone,
        end.subtract(const Duration(microseconds: 1)),
      );
      final after = table.lookupAtUtc(zone, end);
      expect(first.outsideTable, isFalse);
      expect(last.outsideTable, isFalse);
      expect(before.outsideTable, isTrue);
      expect(after.outsideTable, isTrue);
      expect(before.offsetMinutes, first.offsetMinutes);
      expect(before.isDst, first.isDst);
      expect(after.offsetMinutes, last.offsetMinutes);
      expect(after.isDst, last.isDst);
      expect(
        table.lookupAtUtc(zone, DateTime.utc(1900)).offsetMinutes,
        first.offsetMinutes,
      );
      expect(
        table.lookupAtUtc(zone, DateTime.utc(2100)).offsetMinutes,
        last.offsetMinutes,
      );
    }
  });

  test('unknown zone fails for table and facade APIs', () {
    IanaTimeRules.configure(table);
    final utc = DateTime.utc(2026);
    expect(() => table.lookupAtUtc('Unknown/Zone', utc), throwsArgumentError);
    expect(
      () => IanaTimeRules.offsetMinutesAtUtc('Unknown/Zone', utc),
      throwsArgumentError,
    );
    expect(() => IanaTimeRules.isDst('Unknown/Zone', utc), throwsArgumentError);
    expect(
      () => IanaTimeRules.toLocal('Unknown/Zone', utc),
      throwsArgumentError,
    );
    expect(
      () => IanaTimeRules.localWallTimeToUtc('Unknown/Zone', utc),
      throwsArgumentError,
    );
  });

  test('every generated transition switches at the exact UTC instant', () {
    final zones =
        (jsonDecode(source) as Map<String, dynamic>)['zones']
            as Map<String, dynamic>;
    for (final entry in zones.entries) {
      final rows = (entry.value as Map<String, dynamic>)['transitions'] as List;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i] as List;
        final previous = rows[i - 1] as List;
        final utc = DateTime.fromMillisecondsSinceEpoch(
          (row[0] as int) * 1000,
          isUtc: true,
        );
        final before = table.lookupAtUtc(
          entry.key,
          utc.subtract(const Duration(microseconds: 1)),
        );
        final at = table.lookupAtUtc(entry.key, utc);
        expect(
          before.offsetMinutes,
          previous[1],
          reason: '${entry.key} before $utc',
        );
        expect(before.isDst, previous[2] == 1);
        expect(at.offsetMinutes, row[1], reason: '${entry.key} at $utc');
        expect(at.isDst, row[2] == 1);
        expect(at.outsideTable, isFalse);
      }
    }
  });

  test('historical New York rules come from IANA, including before 2007', () {
    expect(
      table
          .lookupAtUtc('America/New_York', DateTime.utc(2006, 3, 20))
          .offsetMinutes,
      -300,
    );
    expect(
      table
          .lookupAtUtc('America/New_York', DateTime.utc(2006, 4, 3))
          .offsetMinutes,
      -240,
    );
  });

  test(
    'rejects malformed transition ordering and incomplete configuration',
    () {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final zones = json['zones'] as Map<String, dynamic>;
      zones.remove('Asia/Tokyo');
      expect(
        () => IanaTimeRules.configure(ZoneTable.fromJson(jsonEncode(json))),
        throwsArgumentError,
      );
      final rows =
          (zones['Europe/London'] as Map<String, dynamic>)['transitions']
              as List;
      rows[1][0] = rows[0][0];
      expect(() => ZoneTable.fromJson(jsonEncode(json)), throwsFormatException);
    },
  );
}
