import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/display/display_catalog.dart';
import '../../../shared/display/display_scope.dart';
import '../domain/now_timeline_models.dart';

class NowTimelinePage extends StatefulWidget {
  const NowTimelinePage({super.key});

  @override
  State<NowTimelinePage> createState() => _NowTimelinePageState();
}

class _NowTimelinePageState extends State<NowTimelinePage> {
  final _store = NowTimelineStore();
  List<TimelineEntry> _entries = const [];
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
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _t(String key) =>
      DisplayScope.of(context).text('nowTimeline.$key');

  Future<void> _delete(TimelineEntry entry) async {
    final next = _entries.where((item) => item.id != entry.id).toList();
    setState(() => _entries = next);
    await _store.saveEntries(next);
  }

  Future<void> _addEntry() async {
    final display = DisplayScope.of(context);
    final created = await showDialog<TimelineEntry>(
      context: context,
      builder: (_) => _AddTimelineEntryDialog(
        catalog: display.catalog,
        locale: display.locale,
      ),
    );
    if (created == null) return;
    final next = [..._entries, created];
    setState(() => _entries = next);
    await _store.saveEntries(next);
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('nowTimeline.title')),
        actions: const [DisplayLocalePicker(compact: true)],
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: Text(_t('add')),
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
                      Text(
                        _t('subtitle'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t('unsupported'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      _NowStrip(
                        entries: _entries,
                        nowUtc: _nowUtc,
                        text: _t,
                      ),
                      const SizedBox(height: 24),
                      _Timeline(
                        entries: _entries,
                        nowUtc: _nowUtc,
                        text: _t,
                        onDelete: _delete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _NowStrip extends StatelessWidget {
  const _NowStrip({
    required this.entries,
    required this.nowUtc,
    required this.text,
  });

  final List<TimelineEntry> entries;
  final DateTime nowUtc;
  final String Function(String key) text;

  @override
  Widget build(BuildContext context) {
    final clocks = entries
        .where(
          (entry) =>
              entry.kind == TimelineKind.person ||
              entry.kind == TimelineKind.place,
        )
        .toList();
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
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dateTime(local),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(entry.zoneName),
                  Text(dst ? text('dst') : text('standard')),
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
  const _Timeline({
    required this.entries,
    required this.nowUtc,
    required this.text,
    required this.onDelete,
  });

  final List<TimelineEntry> entries;
  final DateTime nowUtc;
  final String Function(String key) text;
  final ValueChanged<TimelineEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final rows = <_TimelineRow>[];
    for (final entry in entries) {
      switch (entry.kind) {
        case TimelineKind.person:
        case TimelineKind.place:
          rows.add(
            _TimelineRow(
              entry: entry,
              instantUtc: nowUtc,
              label: text('currentTime'),
            ),
          );
        case TimelineKind.event:
          if (entry.eventUtcMillis != null) {
            rows.add(
              _TimelineRow(
                entry: entry,
                instantUtc: DateTime.fromMillisecondsSinceEpoch(
                  entry.eventUtcMillis!,
                  isUtc: true,
                ),
                label: text('event'),
              ),
            );
          }
        case TimelineKind.schedule:
          _addScheduleRows(rows, entry, nowUtc, text);
      }
    }
    rows.sort((a, b) => a.instantUtc.compareTo(b.instantUtc));

    if (rows.isEmpty) return Center(child: Text(text('empty')));
    return Column(
      children: rows.map((row) {
        final sourceLocal = IanaTimeRules.toLocal(
          row.entry.zoneName,
          row.instantUtc,
        );
        final isNow = row.instantUtc.difference(nowUtc).inMinutes.abs() < 1;
        return Card(
          child: ListTile(
            leading: Icon(_icon(row.entry.kind)),
            title: Text('${_dateTime(sourceLocal)}  ·  ${row.entry.title}'),
            subtitle: Text(
              '${row.label} · ${row.entry.zoneName}'
              '${row.entry.note.isEmpty ? '' : '\n${row.entry.note}'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNow) const Icon(Icons.radio_button_checked, size: 16),
                IconButton(
                  tooltip: text('delete'),
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

void _addScheduleRows(
  List<_TimelineRow> rows,
  TimelineEntry entry,
  DateTime nowUtc,
  String Function(String key) text,
) {
  final localNow = IanaTimeRules.toLocal(entry.zoneName, nowUtc);
  final boundaries = projectScheduleBoundaries(
    zoneName: entry.zoneName,
    localStartMinute: entry.localStartMinute,
    localEndMinute: entry.localEndMinute,
    localDay: localNow,
  );
  for (final boundary in boundaries) {
    rows.add(
      _TimelineRow(
        entry: entry,
        instantUtc: boundary.instantUtc,
        label: text(boundary.isStart ? 'start' : 'end'),
      ),
    );
  }
}

class _TimelineRow {
  const _TimelineRow({
    required this.entry,
    required this.instantUtc,
    required this.label,
  });

  final TimelineEntry entry;
  final DateTime instantUtc;
  final String label;
}

class _AddTimelineEntryDialog extends StatefulWidget {
  const _AddTimelineEntryDialog({
    required this.catalog,
    required this.locale,
  });

  final DisplayCatalog catalog;
  final String locale;

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

  String _t(String key) => widget.catalog.text(
        widget.locale,
        'nowTimeline.$key',
      );

  @override
  void initState() {
    super.initState();
    final next = DateTime.now().add(const Duration(hours: 1));
    _event.text =
        '${next.year}-${_two(next.month)}-${_two(next.day)} '
        '${_two(next.hour)}:${_two(next.minute)}';
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
      setState(() => _error = _t('name'));
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
        eventUtcMillis = IanaTimeRules.localWallTimeToUtc(
          _zone,
          wall,
        ).millisecondsSinceEpoch;
      }
    } on FormatException catch (error) {
      setState(() {
        _error = error.message.toString().startsWith('Non-existent')
            ? _t('invalidTime')
            : _t('invalidFormat');
      });
      return;
    } catch (_) {
      setState(() => _error = _t('invalidFormat'));
      return;
    }

    Navigator.of(context).pop(
      TimelineEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: name,
        kind: _kind,
        zoneName: _zone,
        localStartMinute: startMinute,
        localEndMinute: endMinute,
        eventUtcMillis: eventUtcMillis,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t('add')),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: _t('name')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TimelineKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: _t('kind')),
                items: TimelineKind.values
                    .map(
                      (kind) => DropdownMenuItem(
                        value: kind,
                        child: Text(_t(kind.name)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _zone,
                decoration: InputDecoration(labelText: _t('timezone')),
                items: IanaTimeRules.supportedZones
                    .map(
                      (zone) => DropdownMenuItem(
                        value: zone,
                        child: Text(zone),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _zone = value ?? _zone),
              ),
              if (_kind == TimelineKind.schedule) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _start,
                  decoration: InputDecoration(
                    labelText: '${_t('start')} (HH:MM)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _end,
                  decoration: InputDecoration(
                    labelText: '${_t('end')} (HH:MM)',
                  ),
                ),
              ],
              if (_kind == TimelineKind.event) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _event,
                  decoration: InputDecoration(
                    labelText: '${_t('start')} (YYYY-MM-DD HH:MM)',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: _t('note')),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t('cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(_t('save'))),
      ],
    );
  }
}

int _parseMinute(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) throw const FormatException();
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw const FormatException();
  }
  return hour * 60 + minute;
}

DateTime _parseWallDateTime(String value) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})$',
  ).firstMatch(value.trim());
  if (match == null) throw const FormatException();

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final valueDate = DateTime(year, month, day, hour, minute);
  if (valueDate.year != year ||
      valueDate.month != month ||
      valueDate.day != day ||
      valueDate.hour != hour ||
      valueDate.minute != minute) {
    throw const FormatException();
  }
  return valueDate;
}

IconData _icon(TimelineKind kind) => switch (kind) {
      TimelineKind.person => Icons.person_outline,
      TimelineKind.place => Icons.place_outlined,
      TimelineKind.schedule => Icons.schedule_outlined,
      TimelineKind.event => Icons.event_outlined,
    };

String _dateTime(DateTime value) =>
    '${value.year}-${_two(value.month)}-${_two(value.day)} '
    '${_two(value.hour)}:${_two(value.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');
