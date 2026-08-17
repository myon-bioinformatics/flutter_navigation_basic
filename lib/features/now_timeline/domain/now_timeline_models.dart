import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum TimelineKind { person, place, schedule, event }

class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.title,
    required this.kind,
    required this.zoneName,
    this.localStartMinute,
    this.localEndMinute,
    this.eventUtcMillis,
    this.note = '',
  });

  final String id;
  final String title;
  final TimelineKind kind;
  final String zoneName;
  final int? localStartMinute;
  final int? localEndMinute;
  final int? eventUtcMillis;
  final String note;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'zoneName': zoneName,
        'localStartMinute': localStartMinute,
        'localEndMinute': localEndMinute,
        'eventUtcMillis': eventUtcMillis,
        'note': note,
      };

  factory TimelineEntry.fromJson(Map<String, Object?> json) {
    return TimelineEntry(
      id: json['id']! as String,
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
  static const _localeKey = 'now_timeline.locale.v1';

  Future<List<TimelineEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return defaultEntries();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TimelineEntry.fromJson((item as Map).cast<String, Object?>()))
        .toList(growable: true);
  }

  Future<void> saveEntries(List<TimelineEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<String> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'en';
  }

  Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  static List<TimelineEntry> defaultEntries() => const [
        TimelineEntry(
          id: 'me-tokyo',
          title: 'Me',
          kind: TimelineKind.person,
          zoneName: 'Asia/Tokyo',
        ),
        TimelineEntry(
          id: 'friend-london',
          title: 'Friend',
          kind: TimelineKind.person,
          zoneName: 'Europe/London',
        ),
        TimelineEntry(
          id: 'dentist',
          title: 'Dentist',
          kind: TimelineKind.schedule,
          zoneName: 'Asia/Tokyo',
          localStartMinute: 9 * 60,
          localEndMinute: 18 * 60 + 30,
        ),
        TimelineEntry(
          id: 'nyc',
          title: 'New York',
          kind: TimelineKind.place,
          zoneName: 'America/New_York',
        ),
      ];
}

/// Lightweight runtime rules for the initial IANA identifiers used by Stage 1.
///
/// Python `zoneinfo` under tool/time is the independent oracle. Runtime stays
/// Flutter/Dart-only and database-free. More IANA zones can be added behind this
/// interface without changing TimelineEntry or the UI.
class IanaTimeRules {
  static const supportedZones = <String>[
    'Asia/Tokyo',
    'Europe/London',
    'America/New_York',
  ];

  static int offsetMinutesAtUtc(String zoneName, DateTime utc) {
    final instant = utc.toUtc();
    switch (zoneName) {
      case 'Asia/Tokyo':
        return 540;
      case 'Europe/London':
        return _isLondonDst(instant) ? 60 : 0;
      case 'America/New_York':
        return _isNewYorkDst(instant) ? -240 : -300;
      default:
        throw ArgumentError.value(zoneName, 'zoneName', 'Unsupported IANA zone');
    }
  }

  static DateTime toLocal(String zoneName, DateTime utc) {
    final instant = utc.toUtc();
    return instant.add(Duration(minutes: offsetMinutesAtUtc(zoneName, instant)));
  }

  static DateTime localWallTimeToUtc(String zoneName, DateTime localWallTime) {
    // Resolve once, then correct once. This is sufficient for ordinary wall
    // times and intentionally avoids silently inventing a result inside a DST
    // gap. Ambiguous fall-back times resolve to the earlier occurrence.
    var guess = DateTime.utc(
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );
    var offset = offsetMinutesAtUtc(zoneName, guess);
    guess = guess.subtract(Duration(minutes: offset));
    final corrected = offsetMinutesAtUtc(zoneName, guess);
    if (corrected != offset) {
      guess = DateTime.utc(
        localWallTime.year,
        localWallTime.month,
        localWallTime.day,
        localWallTime.hour,
        localWallTime.minute,
      ).subtract(Duration(minutes: corrected));
    }
    return guess;
  }

  static bool isDst(String zoneName, DateTime utc) {
    if (zoneName == 'Europe/London') return _isLondonDst(utc.toUtc());
    if (zoneName == 'America/New_York') return _isNewYorkDst(utc.toUtc());
    return false;
  }

  static bool _isLondonDst(DateTime utc) {
    final start = DateTime.utc(utc.year, 3, _lastSunday(utc.year, 3), 1);
    final end = DateTime.utc(utc.year, 10, _lastSunday(utc.year, 10), 1);
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  static bool _isNewYorkDst(DateTime utc) {
    final marchSunday = _nthSunday(utc.year, 3, 2);
    final novemberSunday = _nthSunday(utc.year, 11, 1);
    final start = DateTime.utc(utc.year, 3, marchSunday, 7);
    final end = DateTime.utc(utc.year, 11, novemberSunday, 6);
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  static int _nthSunday(int year, int month, int nth) {
    final first = DateTime.utc(year, month, 1);
    final daysUntilSunday = (DateTime.sunday - first.weekday) % 7;
    return 1 + daysUntilSunday + (nth - 1) * 7;
  }

  static int _lastSunday(int year, int month) {
    final last = DateTime.utc(year, month + 1, 0);
    return last.day - ((last.weekday - DateTime.sunday) % 7);
  }
}
