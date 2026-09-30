import 'dart:convert';

class ZoneLookupResult {
  const ZoneLookupResult({
    required this.offsetMinutes,
    required this.isDst,
    required this.outsideTable,
  });

  final int offsetMinutes;
  final bool isDst;
  final bool outsideTable;
}

/// Immutable generated IANA transitions. No Flutter or hand-written DST rules.
class ZoneTable {
  ZoneTable._(this._start, this._end, this._zones);

  final DateTime _start;
  final DateTime _end;
  final Map<String, List<List<int>>> _zones;

  bool containsZone(String zoneName) => _zones.containsKey(zoneName);

  factory ZoneTable.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported zone table schema');
    }
    final window = json['window_utc'] as List<dynamic>;
    final start = DateTime.parse(window[0] as String).toUtc();
    final end = DateTime.parse(window[1] as String).toUtc();
    if (!start.isBefore(end)) {
      throw const FormatException('Invalid zone table window');
    }
    final zones = <String, List<List<int>>>{};
    for (final entry in (json['zones'] as Map<String, dynamic>).entries) {
      final rows =
          ((entry.value as Map<String, dynamic>)['transitions'] as List)
              .map((row) => List<int>.unmodifiable((row as List).cast<int>()))
              .toList(growable: false);
      if (rows.isEmpty) {
        throw const FormatException('Empty zone transitions');
      }
      int? previous;
      for (final row in rows) {
        if (row.length != 3 ||
            (row[2] != 0 && row[2] != 1) ||
            (previous != null && row[0] <= previous) ||
            row[0] < start.millisecondsSinceEpoch ~/ 1000 ||
            row[0] >= end.millisecondsSinceEpoch ~/ 1000) {
          throw const FormatException('Invalid zone transition');
        }
        previous = row[0];
      }
      if (rows.first[0] != start.millisecondsSinceEpoch ~/ 1000) {
        throw const FormatException('Missing initial zone state');
      }
      zones[entry.key] = List<List<int>>.unmodifiable(rows);
    }
    return ZoneTable._(start, end, Map.unmodifiable(zones));
  }

  /// Window is [start, end). Outside it, clamp to the nearest endpoint state.
  ZoneLookupResult lookupAtUtc(String zoneName, DateTime utc) {
    final rows = _zones[zoneName];
    if (rows == null) {
      throw ArgumentError.value(zoneName, 'zoneName', 'Unsupported IANA zone');
    }
    final instant = utc.toUtc();
    final outside = instant.isBefore(_start) || !instant.isBefore(_end);
    final micros = instant.microsecondsSinceEpoch;
    var low = 0;
    var high = rows.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (rows[middle][0] * Duration.microsecondsPerSecond <= micros) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    final row = rows[low];
    return ZoneLookupResult(
      offsetMinutes: row[1],
      isDst: row[2] == 1,
      outsideTable: outside,
    );
  }
}
