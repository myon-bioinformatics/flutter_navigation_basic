import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/now_timeline_models.dart';
import 'now_timeline_strings.dart';

class NowTimelinePage extends StatefulWidget {
  const NowTimelinePage({super.key});

  @override
  State<NowTimelinePage> createState() => _NowTimelinePageState();
}

class _NowTimelinePageState extends State<NowTimelinePage> {
  final _store = NowTimelineStore();
  List<TimelineEntry> _entries = const [];
  String _locale = 'en';
  DateTime _nowUtc = DateTime.now().toUtc();
  Timer? _ticker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _nowUtc = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _store.loadEntries();
    final locale = await _store.loadLocale();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _locale = NowTimelineStrings.supportedLocales.contains(locale) ? locale : 'en';
      _loading = false;
    });
  }

  Future<void> _setLocale(String value) async {
    setState(() => _locale = value);
    await _store.saveLocale(value);
  }

  Future<void> _delete(TimelineEntry entry) async {
    final next = _entries.where((item) => item.id != entry.id).toList();
    setState(() => _entries = next);
    await _store.saveEntries(next);
  }

  Future<void> _addEntry() async {
    final created = await showDialog<TimelineEntry>(
      context: context,
      builder: (_) => _AddTimelineEntryDialog(strings: NowTimelineStrings(_locale)),
    );
    if (created == null) return;
    final next = [..._entries, created];
    setState(() => _entries = next);
    await _store.saveEntries(next);
  }

  @override
  Widget build(BuildContext context) {
    final strings = NowTimelineStrings(_locale);
    return Directionality(
      textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.text('title')),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _locale,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: NowTimelineStrings.supportedLocales
                    .map((locale) => DropdownMenuItem(value: locale, child: Text(locale.toUpperCase())))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _setLocale(value);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addEntry,
          icon: const Icon(Icons.add),
          label: Text(strings.text('add')),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(strings.text('subtitle'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(strings.text('unsupported'), style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 20),
                        _NowStrip(entries: _entries, nowUtc: _nowUtc, strings: strings),
                        const SizedBox(height: 24),
                        _Timeline(entries: _entries, nowUtc: _nowUtc, strings: strings, onDelete: _delete),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NowStrip extends StatelessWidget {
  const _NowStrip({required this.entries, required this.nowUtc, required this.strings});

  final List<TimelineEntry> entries;
  final DateTime nowUtc;
  final NowTimelineStrings strings;

  @override
  Widget build(BuildContext context) {
    final clocks = entries.where((e) => e.kind == TimelineKind.person || e.kind == TimelineKind.place).toList();
    if (clocks.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: clocks.map((entry) {
        final local = IanaTimeRules.toLocal(entry.zoneName, nowUtc);
        final dst = IanaTimeRules.isDst(entry.zoneName, nowUtc);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(_dateTime(local), style: Theme.of(context).textTheme.headlineSmall),
                  Text(entry.zoneName),
                  Text(dst ? strings.text('dst') : strings.text('standard')),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries, required this.nowUtc, required this.strings, required this.onDelete});

  final List<TimelineEntry> entries;
  final DateTime nowUtc;
  final NowTimelineStrings strings;
  final ValueChanged<TimelineEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final rows = <_TimelineRow>[];
    for (final entry in entries) {
      switch (entry.kind) {
        case TimelineKind.person:
        case TimelineKind.place:
          rows.add(_TimelineRow(entry: entry, instantUtc: nowUtc, label: strings.text('currentTime')));
        case TimelineKind.event:
          if (entry.eventUtcMillis != null) {
            rows.add(_TimelineRow(
              entry: entry,
              instantUtc: DateTime.fromMillisecondsSinceEpoch(entry.eventUtcMillis!, isUtc: true),
              label: strings.text('event'),
            ));
          }
        case TimelineKind.schedule:
          final sourceNow = IanaTimeRules.toLocal(entry.zoneName, nowUtc);
          final start = entry.localStartMinute;
          final end = entry.localEndMinute;
          if (start != null) {
            final wall = DateTime(sourceNow.year, sourceNow.month, sourceNow.day, start ~/ 60, start % 60);
            rows.add(_TimelineRow(entry: entry, instantUtc: IanaTimeRules.localWallTimeToUtc(entry.zoneName, wall), label: strings.text('start')));
          }
          if (end != null) {
            final wall = DateTime(sourceNow.year, sourceNow.month, sourceNow.day, end ~/ 60, end % 60);
            rows.add(_TimelineRow(entry: entry, instantUtc: IanaTimeRules.localWallTimeToUtc(entry.zoneName, wall), label: strings.text('end')));
          }
      }
    }
    rows.sort((a, b) => a.instantUtc.compareTo(b.instantUtc));

    if (rows.isEmpty) return Center(child: Text(strings.text('empty')));
    return Column(
      children: rows.map((row) {
        final sourceLocal = IanaTimeRules.toLocal(row.entry.zoneName, row.instantUtc);
        final delta = row.instantUtc.difference(nowUtc);
        final isNow = delta.inMinutes.abs() < 1;
        return Card(
          child: ListTile(
            leading: Icon(_icon(row.entry.kind)),
            title: Text('${_dateTime(sourceLocal)}  ·  ${row.entry.title}'),
            subtitle: Text('${row.label} · ${row.entry.zoneName}${row.entry.note.isEmpty ? '' : '\n${row.entry.note}'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNow) const Icon(Icons.radio_button_checked, size: 16),
                IconButton(
                  tooltip: strings.text('delete'),
                  onPressed: () => onDelete(row.entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineRow {
  const _TimelineRow({required this.entry, required this.instantUtc, required this.label});
  final TimelineEntry entry;
  final DateTime instantUtc;
  final String label;
}

class _AddTimelineEntryDialog extends StatefulWidget {
  const _AddTimelineEntryDialog({required this.strings});
  final NowTimelineStrings strings;

  @override
  State<_AddTimelineEntryDialog> createState() => _AddTimelineEntryDialogState();
}

class _AddTimelineEntryDialogState extends State<_AddTimelineEntryDialog> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _start = TextEditingController(text: '09:00');
  final _end = TextEditingController(text: '17:00');
  final _event = TextEditingController();
  TimelineKind _kind = TimelineKind.person;
  String _zone = IanaTimeRules.supportedZones.first;
  String? _error;

  @override
  void initState() {
    super.initState();
    final next = DateTime.now().add(const Duration(hours: 1));
    _event.text = '${next.year}-${_two(next.month)}-${_two(next.day)} ${_two(next.hour)}:${_two(next.minute)}';
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _start.dispose();
    _end.dispose();
    _event.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = widget.strings.text('name'));
      return;
    }
    int? startMinute;
    int? endMinute;
    int? eventUtcMillis;
    try {
      if (_kind == TimelineKind.schedule) {
        startMinute = _parseMinute(_start.text);
        endMinute = _parseMinute(_end.text);
      } else if (_kind == TimelineKind.event) {
        final wall = _parseWallDateTime(_event.text);
        eventUtcMillis = IanaTimeRules.localWallTimeToUtc(_zone, wall).millisecondsSinceEpoch;
      }
    } catch (_) {
      setState(() => _error = _kind == TimelineKind.event ? 'YYYY-MM-DD HH:MM' : 'HH:MM');
      return;
    }
    Navigator.of(context).pop(TimelineEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: name,
      kind: _kind,
      zoneName: _zone,
      localStartMinute: startMinute,
      localEndMinute: endMinute,
      eventUtcMillis: eventUtcMillis,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.text('add')),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: InputDecoration(labelText: s.text('name'))),
              const SizedBox(height: 12),
              DropdownButtonFormField<TimelineKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: s.text('kind')),
                items: TimelineKind.values.map((kind) => DropdownMenuItem(value: kind, child: Text(s.text(kind.name)))).toList(),
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _zone,
                decoration: InputDecoration(labelText: s.text('timezone')),
                items: IanaTimeRules.supportedZones.map((zone) => DropdownMenuItem(value: zone, child: Text(zone))).toList(),
                onChanged: (value) => setState(() => _zone = value ?? _zone),
              ),
              if (_kind == TimelineKind.schedule) ...[
                const SizedBox(height: 12),
                TextField(controller: _start, decoration: InputDecoration(labelText: '${s.text('start')} (HH:MM)')),
                const SizedBox(height: 12),
                TextField(controller: _end, decoration: InputDecoration(labelText: '${s.text('end')} (HH:MM)')),
              ],
              if (_kind == TimelineKind.event) ...[
                const SizedBox(height: 12),
                TextField(controller: _event, decoration: InputDecoration(labelText: '${s.text('start')} (YYYY-MM-DD HH:MM)')),
              ],
              const SizedBox(height: 12),
              TextField(controller: _note, decoration: InputDecoration(labelText: s.text('note'))),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.text('cancel'))),
        FilledButton(onPressed: _save, child: Text(s.text('save'))),
      ],
    );
  }
}

int _parseMinute(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) throw const FormatException();
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) throw const FormatException();
  return hour * 60 + minute;
}

DateTime _parseWallDateTime(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) throw const FormatException();
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

IconData _icon(TimelineKind kind) => switch (kind) {
      TimelineKind.person => Icons.person_outline,
      TimelineKind.place => Icons.place_outlined,
      TimelineKind.schedule => Icons.schedule_outlined,
      TimelineKind.event => Icons.event_outlined,
    };

String _dateTime(DateTime value) => '${value.year}-${_two(value.month)}-${_two(value.day)} ${_two(value.hour)}:${_two(value.minute)}';
String _two(int value) => value.toString().padLeft(2, '0');
