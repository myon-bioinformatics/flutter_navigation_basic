import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/display/display_scope.dart';
import '../domain/coordinate_formatter.dart';

class CoordinateToolPage extends StatefulWidget {
  const CoordinateToolPage({super.key});

  @override
  State<CoordinateToolPage> createState() => _CoordinateToolPageState();
}

class _CoordinateToolPageState extends State<CoordinateToolPage> {
  final _latitude = TextEditingController(text: '35.681236');
  final _longitude = TextEditingController(text: '139.767125');
  final _customRadius = TextEditingController(text: '100');
  CoordinateTolerancePreset _preset = CoordinateTolerancePreset.building;
  int _zoom = 16;
  CoordinateValue? _value;
  CoordinateToleranceArea? _area;
  XyzTile? _tile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _customRadius.dispose();
    super.dispose();
  }

  double _selectedRadius() {
    final presetRadius = _preset.radiusMeters;
    if (presetRadius != null) return presetRadius;
    final radius = double.tryParse(_customRadius.text.trim());
    if (radius == null || !radius.isFinite || radius <= 0) {
      throw const FormatException('Custom radius must be a number greater than zero.');
    }
    return radius;
  }

  void _convert() {
    CoordinateValue value;
    XyzTile tile;
    try {
      value = CoordinateValue.parse(
        latitude: _latitude.text,
        longitude: _longitude.text,
      );
      tile = value.xyzTile(_zoom);
    } on FormatException catch (error) {
      setState(() {
        _value = null;
        _area = null;
        _tile = null;
        _error = error.message.toString();
      });
      return;
    }

    CoordinateToleranceArea? area;
    String? areaError;
    try {
      area = value.toleranceArea(_selectedRadius());
    } on FormatException catch (error) {
      areaError = error.message.toString();
    }

    setState(() {
      _value = value;
      _area = area;
      _tile = tile;
      _error = areaError;
    });
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          display.text('coordinate.copied', arguments: {'label': label}),
        ),
      ),
    );
  }

  String _presetLabel(DisplayController display, CoordinateTolerancePreset preset) {
    final key = switch (preset) {
      CoordinateTolerancePreset.exactGps => 'coordinate.preset.exactGps',
      CoordinateTolerancePreset.building => 'coordinate.preset.building',
      CoordinateTolerancePreset.stationCampus => 'coordinate.preset.stationCampus',
      CoordinateTolerancePreset.park => 'coordinate.preset.park',
      CoordinateTolerancePreset.district => 'coordinate.preset.district',
      CoordinateTolerancePreset.custom => 'coordinate.preset.custom',
    };
    final label = display.text(key);
    return preset.radiusMeters == null
        ? label
        : '$label · ${preset.radiusMeters!.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    final value = _value;
    final area = _area;
    final tile = _tile;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('coordinate.title')),
        actions: const [DisplayLocalePicker(compact: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t('coordinate.subtitle'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                _SectionTitle(title: t('coordinate.point'), icon: Icons.place_outlined),
                const SizedBox(height: 12),
                TextField(
                  controller: _latitude,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: t('coordinate.latitude'),
                    helperText: '-90 to 90',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _longitude,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: t('coordinate.longitude'),
                    helperText: '-180 to 180',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _convert,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(t('coordinate.calculate')),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (value != null) ...[
                  const SizedBox(height: 20),
                  _ResultCard(title: t('coordinate.decimal'), value: value.decimalDegrees, copyTooltip: t('common.copy'), onCopy: () => _copy(value.decimalDegrees, t('coordinate.decimal'))),
                  const SizedBox(height: 12),
                  _ResultCard(title: t('coordinate.dms'), value: value.dms, copyTooltip: t('common.copy'), onCopy: () => _copy(value.dms, t('coordinate.dms'))),
                  const SizedBox(height: 28),
                  _SectionTitle(title: t('coordinate.tolerance'), icon: Icons.radar_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CoordinateTolerancePreset>(
                    initialValue: _preset,
                    decoration: InputDecoration(labelText: t('coordinate.areaPreset'), border: const OutlineInputBorder()),
                    items: CoordinateTolerancePreset.values
                        .map((preset) => DropdownMenuItem(value: preset, child: Text(_presetLabel(display, preset))))
                        .toList(),
                    onChanged: (preset) {
                      if (preset == null) return;
                      setState(() => _preset = preset);
                      _convert();
                    },
                  ),
                  if (_preset == CoordinateTolerancePreset.custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customRadius,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t('coordinate.customRadius'),
                        helperText: t('coordinate.radiusHelper'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _convert(),
                    ),
                  ],
                  if (area != null) ...[
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.centerRadius'), value: area.centerRadiusText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.centerRadiusText, t('coordinate.centerRadius'))),
                    const SizedBox(height: 28),
                    _SectionTitle(title: t('coordinate.bounds'), icon: Icons.crop_free_outlined),
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.looseBox'), value: area.boundsText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.boundsText, t('coordinate.looseBox'))),
                    const SizedBox(height: 12),
                    _ResultCard(title: 'BBox [west, south, east, north]', value: area.bboxText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.bboxText, 'BBox')),
                    const SizedBox(height: 12),
                    _ResultCard(title: 'JSON', value: area.jsonText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.jsonText, 'JSON')),
                    if (area.wrapsAntimeridian) ...[
                      const SizedBox(height: 8),
                      Text(t('coordinate.antimeridian')),
                    ],
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: '4. Platform formats',
                      icon: Icons.integration_instructions_outlined,
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'Google Maps JavaScript · Circle',
                      value: area.googleMapsJavaScript,
                      onCopy: () => _copy(
                        area.googleMapsJavaScript,
                        'Google Maps JavaScript circle',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'Apple MapKit · MKCircle (Swift)',
                      value: area.appleMapKitSwift,
                      onCopy: () => _copy(
                        area.appleMapKitSwift,
                        'Apple MapKit circle',
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(title: t('coordinate.xyzTile'), icon: Icons.grid_4x4_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _zoom,
                    decoration: InputDecoration(labelText: t('coordinate.zoom'), border: const OutlineInputBorder()),
                    items: [12, 13, 14, 15, 16, 17, 18, 19]
                        .map((zoom) => DropdownMenuItem(value: zoom, child: Text('z$zoom')))
                        .toList(),
                    onChanged: (zoom) {
                      if (zoom == null) return;
                      setState(() => _zoom = zoom);
                      _convert();
                    },
                  ),
                  if (tile != null) ...[
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.xyzTile'), value: tile.text, copyTooltip: t('common.copy'), onCopy: () => _copy(tile.text, t('coordinate.xyzTile'))),
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.tilePath'), value: tile.path, copyTooltip: t('common.copy'), onCopy: () => _copy(tile.path, t('coordinate.tilePath'))),
                  ],
                  const SizedBox(height: 16),
                  Text(t('coordinate.disclaimer'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.copyTooltip,
    required this.onCopy,
  });

  final String title;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          subtitle: SelectableText(value),
          trailing: IconButton(
            tooltip: copyTooltip,
            onPressed: onCopy,
            icon: const Icon(Icons.copy),
          ),
        ),
      );
}
