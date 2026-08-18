import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    try {
      final value = CoordinateValue.parse(
        latitude: _latitude.text,
        longitude: _longitude.text,
      );
      final area = value.toleranceArea(_selectedRadius());
      final tile = value.xyzTile(_zoom);
      setState(() {
        _value = value;
        _area = area;
        _tile = tile;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _value = null;
        _area = null;
        _tile = null;
        _error = error.message.toString();
      });
    }
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $label.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final area = _area;
    final tile = _tile;
    return Scaffold(
      appBar: AppBar(title: const Text('Latitude / Longitude')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Treat a coordinate as either an exact point or a loose real-world area, then copy reusable bounds and map-tile values.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: '1. Point', icon: Icons.place_outlined),
                const SizedBox(height: 12),
                TextField(
                  controller: _latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    helperText: '-90 to 90',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    helperText: '-180 to 180',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _convert,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (value != null) ...[
                  const SizedBox(height: 20),
                  _ResultCard(
                    title: 'Decimal degrees',
                    value: value.decimalDegrees,
                    onCopy: () => _copy(value.decimalDegrees, 'decimal coordinates'),
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'Degrees / minutes / seconds (DMS)',
                    value: value.dms,
                    onCopy: () => _copy(value.dms, 'DMS coordinates'),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(title: '2. Tolerance', icon: Icons.radar_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CoordinateTolerancePreset>(
                    initialValue: _preset,
                    decoration: const InputDecoration(
                      labelText: 'Area preset',
                      border: OutlineInputBorder(),
                    ),
                    items: CoordinateTolerancePreset.values
                        .map(
                          (preset) => DropdownMenuItem(
                            value: preset,
                            child: Text(
                              preset.radiusMeters == null
                                  ? preset.label
                                  : '${preset.label} · ${preset.radiusMeters!.toInt()} m',
                            ),
                          ),
                        )
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
                      decoration: const InputDecoration(
                        labelText: 'Custom radius (m)',
                        helperText: 'Distance from the center point',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _convert(),
                    ),
                  ],
                  if (area != null) ...[
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'Center + radius',
                      value: area.centerRadiusText,
                      onCopy: () => _copy(area.centerRadiusText, 'center and radius'),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(title: '3. Bounds', icon: Icons.crop_free_outlined),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'Loose bounding box',
                      value: area.boundsText,
                      onCopy: () => _copy(area.boundsText, 'bounds'),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'BBox [west, south, east, north]',
                      value: area.bboxText,
                      onCopy: () => _copy(area.bboxText, 'bbox'),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'JSON',
                      value: area.jsonText,
                      onCopy: () => _copy(area.jsonText, 'JSON area'),
                    ),
                    if (area.wrapsAntimeridian) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'This area crosses the ±180° antimeridian. Consumers of the bbox must support wrapped longitude ranges.',
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(title: '4. XYZ tile', icon: Icons.grid_4x4_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _zoom,
                    decoration: const InputDecoration(
                      labelText: 'Web Mercator zoom',
                      border: OutlineInputBorder(),
                    ),
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
                    _ResultCard(
                      title: 'XYZ tile',
                      value: tile.text,
                      onCopy: () => _copy(tile.text, 'XYZ tile'),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: 'Tile path',
                      value: tile.path,
                      onCopy: () => _copy(tile.path, 'tile path'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Tolerance presets are intentionally loose heuristics for GPS drift, representative points, large facilities, parks, campuses and similar real-world ambiguity. They are not survey-grade accuracy guarantees. No map, geocoding service, server or database is used.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.onCopy,
  });

  final String title;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: SelectableText(value),
        trailing: IconButton(
          tooltip: 'Copy',
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
        ),
      ),
    );
  }
}
