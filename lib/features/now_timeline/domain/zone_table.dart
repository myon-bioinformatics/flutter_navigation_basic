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
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Zone table must be an object');
    }
    final json = decoded;
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported zone table schema');
    }
    final window = json['window_utc'];
    if (window is! List ||
        window.length != 2 ||
        window[0] is! String ||
        window[1] is! String) {
      throw const FormatException('Invalid zone table window');
    }
    final start = DateTime.parse(window[0] as String).toUtc();
    final end = DateTime.parse(window[1] as String).toUtc();
    if (!start.isBefore(end)) {
      throw const FormatException('Invalid zone table window');
    }
    final zones = <String, List<List<int>>>{};
    final rawZones = json['zones'];
    if (rawZones is! Map<String, dynamic> || rawZones.isEmpty) {
      throw const FormatException('Invalid zone table zones');
    }
    for (final entry in rawZones.entries) {
      final value = entry.value;
      if (entry.key.isEmpty ||
          value is! Map<String, dynamic> ||
          value['transitions'] is! List) {
        throw const FormatException('Invalid zone transitions');
      }
      final rows = <List<int>>[];
      for (final rawRow in value['transitions'] as List) {
        if (rawRow is! List ||
            rawRow.length != 3 ||
            rawRow.any((item) => item is! int)) {
          throw const FormatException('Invalid zone transition types');
        }
        rows.add(List<int>.unmodifiable(rawRow.cast<int>()));
      }
      if (rows.isEmpty) {
        throw const FormatException('Empty zone transitions');
      }
      int? previous;
      for (final row in rows) {
        if (row[1] < -24 * 60 ||
            row[1] > 24 * 60 ||
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
