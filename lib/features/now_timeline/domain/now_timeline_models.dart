import 'dart:convert';

import 'zone_table.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum TimelineKind { person, place, schedule, event }

class TimelineEntry {
  const TimelineEntry({
    required this.timelineEntryId,
    required this.title,
    required this.kind,
    required this.zoneName,
    this.localStartMinute,
    this.localEndMinute,
    this.eventUtcMillis,
    this.note = '',
  });

  final String timelineEntryId;
  final String title;
  final TimelineKind kind;
  final String zoneName;
  final int? localStartMinute;
  final int? localEndMinute;
  final int? eventUtcMillis;
  final String note;

  Map<String, Object?> toJson() => {
        'timelineEntryId': timelineEntryId,
        'title': title,
        'kind': kind.name,
        'zoneName': zoneName,
        'localStartMinute': localStartMinute,
        'localEndMinute': localEndMinute,
        'eventUtcMillis': eventUtcMillis,
        'note': note,
      };

  factory TimelineEntry.fromJson(Map<String, Object?> json) {
    final rawId = json['timelineEntryId'] ?? json['id'];
    return TimelineEntry(
      timelineEntryId: rawId! as String,
      title: json['title']! as String,
      kind: TimelineKind.values.byName(json['kind']! as String),
      zoneName: json['zoneName']! as String,
      localStartMinute: json['localStartMinute'] as int?,
      localEndMinute: json['localEndMinute'] as int?,
      eventUtcMillis: json['eventUtcMillis'] as int?,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class NowTimelineStore {
  static const _entriesKey = 'now_timeline.entries.v1';

  // Chains writes so they land on disk in call order rather than completion
  // order. Without this, two rapid saveEntries() calls (e.g. fast
  // double-tap add/delete) can race on the underlying platform channel and
  // let an older snapshot overwrite a newer one.
  Future<void> _entriesWriteQueue = Future.value();

  Future<List<TimelineEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return defaultEntries();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TimelineEntry.fromJson((item as Map).cast<String, Object?>()))
        .toList(growable: true);
  }

  Future<void> saveEntries(List<TimelineEntry> entries) {
    final scheduled = _entriesWriteQueue.then((_) => _writeEntries(entries));
    _entriesWriteQueue = scheduled.catchError((_) {});
    return scheduled;
  }

  Future<void> _writeEntries(List<TimelineEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  static List<TimelineEntry> defaultEntries() => const [
        TimelineEntry(
          timelineEntryId: 'me-tokyo',
          title: 'Me',
          kind: TimelineKind.person,
          zoneName: 'Asia/Tokyo',
        ),
        TimelineEntry(
          timelineEntryId: 'friend-london',
          title: 'Friend',
          kind: TimelineKind.person,
          zoneName: 'Europe/London',
        ),
        TimelineEntry(
          timelineEntryId: 'dentist',
          title: 'Dentist',
          kind: TimelineKind.schedule,
          zoneName: 'Asia/Tokyo',
          localStartMinute: 9 * 60,
          localEndMinute: 18 * 60 + 30,
        ),
        TimelineEntry(
          timelineEntryId: 'nyc',
          title: 'New York',
          kind: TimelineKind.place,
          zoneName: 'America/New_York',
        ),
      ];
}

/// Synchronous facade over the generated IANA table configured at startup.
class IanaTimeRules {
  static const supportedZones = <String>[
    'Asia/Tokyo',
    'Europe/London',
    'America/New_York',
  ];

  static ZoneTable? _table;

  static void configure(ZoneTable table) {
    for (final zone in supportedZones) {
      if (!table.containsZone(zone)) {
        throw ArgumentError.value(zone, 'table', 'Missing supported zone');
      }
    }
    _table = table;
  }

  static ZoneLookupResult lookupAtUtc(String zoneName, DateTime utc) {
    final table = _table;
    if (table == null) {
      throw StateError('IanaTimeRules.configure() has not been called');
    }
    return table.lookupAtUtc(zoneName, utc);
  }

  static int offsetMinutesAtUtc(String zoneName, DateTime utc) =>
      lookupAtUtc(zoneName, utc).offsetMinutes;

  static DateTime toLocal(String zoneName, DateTime utc) {
    final instant = utc.toUtc();
    return instant.add(
      Duration(minutes: offsetMinutesAtUtc(zoneName, instant)),
    );
  }

  static DateTime localWallTimeToUtc(String zoneName, DateTime localWallTime) {
    final wallAsUtc = DateTime.utc(
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );

    var offset = offsetMinutesAtUtc(zoneName, wallAsUtc);
    var resolved = wallAsUtc.subtract(Duration(minutes: offset));
    final correctedOffset = offsetMinutesAtUtc(zoneName, resolved);
    if (correctedOffset != offset) {
      offset = correctedOffset;
      resolved = wallAsUtc.subtract(Duration(minutes: offset));
    }

    final roundTrip = toLocal(zoneName, resolved);
    if (!_sameWallMinute(roundTrip, localWallTime)) {
      throw FormatException(
        'Non-existent local wall time for $zoneName: '
        '${localWallTime.year}-${localWallTime.month}-${localWallTime.day} '
        '${localWallTime.hour}:${localWallTime.minute}',
      );
    }
    return resolved;
  }

  static bool isDst(String zoneName, DateTime utc) =>
      lookupAtUtc(zoneName, utc).isDst;

  static bool _sameWallMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

/// One projected schedule boundary, already resolved to a UTC instant.
class ScheduleBoundaryInstant {
  const ScheduleBoundaryInstant({
    required this.instantUtc,
    required this.isStart,
  });

  final DateTime instantUtc;
  final bool isStart;
}

/// Projects a schedule entry's local start/end minutes onto [localDay] and
/// resolves each boundary to a UTC instant.
///
/// Overnight schedules (`localEndMinute < localStartMinute`) project the end
/// boundary onto the day after [localDay]. A boundary that lands in a DST
/// spring-forward gap (a local wall time that never occurs) is skipped
/// rather than thrown, so a schedule saved on an ordinary day cannot crash
/// rendering on the one day a year its start/end becomes momentarily
/// non-existent.
List<ScheduleBoundaryInstant> projectScheduleBoundaries({
  required String zoneName,
  required int? localStartMinute,
  required int? localEndMinute,
  required DateTime localDay,
}) {
  final boundaries = <ScheduleBoundaryInstant>[];
  if (localStartMinute == null && localEndMinute == null) return boundaries;

  final day = DateTime(localDay.year, localDay.month, localDay.day);

  if (localStartMinute != null) {
    final wall = DateTime(
      day.year,
      day.month,
      day.day,
      localStartMinute ~/ 60,
      localStartMinute % 60,
    );
    final instant = _tryLocalWallTimeToUtc(zoneName, wall);
    if (instant != null) {
      boundaries.add(
        ScheduleBoundaryInstant(instantUtc: instant, isStart: true),
      );
    }
  }

  if (localEndMinute != null) {
    final overnight =
        localStartMinute != null && localEndMinute < localStartMinute;
    final endDay = overnight ? day.add(const Duration(days: 1)) : day;
    final wall = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      localEndMinute ~/ 60,
      localEndMinute % 60,
    );
    final instant = _tryLocalWallTimeToUtc(zoneName, wall);
    if (instant != null) {
      boundaries.add(
        ScheduleBoundaryInstant(instantUtc: instant, isStart: false),
      );
    }
  }

  return boundaries;
}

DateTime? _tryLocalWallTimeToUtc(String zoneName, DateTime wall) {
  try {
    return IanaTimeRules.localWallTimeToUtc(zoneName, wall);
  } on FormatException {
    return null;
  }
}
