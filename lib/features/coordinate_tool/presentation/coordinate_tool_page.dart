import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/display/display_scope.dart';
import '../../../shared/platform/open_external_url.dart';
import '../domain/bounding_box.dart';
import '../domain/coordinate_formatter.dart';

class CoordinateToolPage extends StatefulWidget {
  const CoordinateToolPage({super.key});

  @override
  State<CoordinateToolPage> createState() => _CoordinateToolPageState();
}

class _CoordinateToolPageState extends State<CoordinateToolPage> {
  final _latitude = TextEditingController(text: '35.681236');
  final _longitude = TextEditingController(text: '139.767125');
  final _mapsUrl = TextEditingController();
  final _customRadius = TextEditingController(text: '100');
  final _boxSouth = TextEditingController(text: '35.676746');
  final _boxWest = TextEditingController(text: '139.756060');
  final _boxNorth = TextEditingController(text: '35.685726');
  final _boxEast = TextEditingController(text: '139.778190');
  final _boxCenterLatitude = TextEditingController(text: '35.681236');
  final _boxCenterLongitude = TextEditingController(text: '139.767125');
  final _boxRadiusMeters = TextEditingController(text: '1000');
  BoundingBox? _manualBox;
  String? _manualBoxError;
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
    _validateManualBox();
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _mapsUrl.dispose();
    _customRadius.dispose();
    _boxSouth.dispose();
    _boxWest.dispose();
    _boxNorth.dispose();
    _boxEast.dispose();
    _boxCenterLatitude.dispose();
    _boxCenterLongitude.dispose();
    _boxRadiusMeters.dispose();
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

  void _applyMapsUrl() {
    final display = DisplayScope.of(context);
    final value = CoordinateValue.tryParseMapsUrl(_mapsUrl.text);
    if (value == null) {
      setState(() {
        _error = display.text('coordinate.mapsUrlInvalid');
      });
      return;
    }
    _latitude.text = value.latitude.toStringAsFixed(6);
    _longitude.text = value.longitude.toStringAsFixed(6);
    _convert();
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

  Future<void> _openMap(Uri uri, String label) async {
    final opened = await openExternalUrl(uri);
    if (!mounted || opened) return;
    final display = DisplayScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          display.text('coordinate.openFailed', arguments: {'label': label}),
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

  void _validateManualBox() {
    try {
      final box = BoundingBox.fromBounds(
        south: _boxSouth.text,
        west: _boxWest.text,
        north: _boxNorth.text,
        east: _boxEast.text,
      );
      setState(() {
        _manualBox = box;
        _manualBoxError = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _manualBox = null;
        _manualBoxError = error.message;
      });
    }
  }

  void _generateManualBox() {
    try {
      final latitude = double.parse(_boxCenterLatitude.text.trim());
      final longitude = double.parse(_boxCenterLongitude.text.trim());
      final radius = double.parse(_boxRadiusMeters.text.trim());
      final box = BoundingBox.fromCenterRadius(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
      _boxSouth.text = box.south.toStringAsFixed(6);
      _boxWest.text = box.west.toStringAsFixed(6);
      _boxNorth.text = box.north.toStringAsFixed(6);
      _boxEast.text = box.east.toStringAsFixed(6);
      setState(() {
        _manualBox = box;
        _manualBoxError = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _manualBox = null;
        _manualBoxError = error.message;
      });
    } catch (error) {
      setState(() {
        _manualBox = null;
        _manualBoxError = error.toString();
      });
    }
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
                  controller: _mapsUrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyMapsUrl(),
                  decoration: InputDecoration(
                    labelText: t('coordinate.mapsUrlPaste'),
                    helperText: t('coordinate.mapsUrlHelper'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _applyMapsUrl,
                  icon: const Icon(Icons.content_paste_go_outlined),
                  label: Text(t('coordinate.mapsUrlApply')),
                ),
                const SizedBox(height: 16),
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
                  _SectionTitle(title: t('coordinate.mapLinks'), icon: Icons.map_outlined),
                  const SizedBox(height: 12),
                  _MapLinkCard(
                    title: 'Google Maps',
                    uri: value.googleMapsUri,
                    openLabel: t('coordinate.openGoogleMaps'),
                    copyTooltip: t('common.copy'),
                    onOpen: () => _openMap(value.googleMapsUri, 'Google Maps'),
                    onCopy: () => _copy(
                      value.googleMapsUri.toString(),
                      t('coordinate.googleMapsUrl'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MapLinkCard(
                    title: 'Apple Maps',
                    uri: value.appleMapsUri,
                    openLabel: t('coordinate.openAppleMaps'),
                    copyTooltip: t('common.copy'),
                    onOpen: () => _openMap(value.appleMapsUri, 'Apple Maps'),
                    onCopy: () => _copy(
                      value.appleMapsUri.toString(),
                      t('coordinate.appleMapsUrl'),
                    ),
                  ),
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
                    _SectionTitle(title: t('coordinate.mapAreaLinks'), icon: Icons.travel_explore_outlined),
                    const SizedBox(height: 12),
                    _MapLinkCard(
                      title: 'Google Maps',
                      uri: area.googleMapsAreaUri,
                      openLabel: t('coordinate.openGoogleMaps'),
                      copyTooltip: t('common.copy'),
                      onOpen: () => _openMap(area.googleMapsAreaUri, 'Google Maps'),
                      onCopy: () => _copy(
                        area.googleMapsAreaUri.toString(),
                        t('coordinate.googleMapsAreaUrl'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MapLinkCard(
                      title: 'Apple Maps',
                      uri: area.appleMapsAreaUri,
                      openLabel: t('coordinate.openAppleMaps'),
                      copyTooltip: t('common.copy'),
                      onOpen: () => _openMap(area.appleMapsAreaUri, 'Apple Maps'),
                      onCopy: () => _copy(
                        area.appleMapsAreaUri.toString(),
                        t('coordinate.appleMapsAreaUrl'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(title: t('coordinate.bounds'), icon: Icons.crop_free_outlined),
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.looseBox'), value: area.boundsText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.boundsText, t('coordinate.looseBox'))),
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.bbox'), value: area.bboxText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.bboxText, t('coordinate.bbox'))),
                    const SizedBox(height: 12),
                    _ResultCard(title: t('coordinate.json'), value: area.jsonText, copyTooltip: t('common.copy'), onCopy: () => _copy(area.jsonText, t('coordinate.json'))),
                    if (area.wrapsAntimeridian) ...[
                      const SizedBox(height: 8),
                      Text(t('coordinate.antimeridian')),
                    ],
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: t('coordinate.platformFormats'),
                      icon: Icons.integration_instructions_outlined,
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: t('coordinate.googleCircle'),
                      value: area.googleMapsJavaScript,
                      copyTooltip: t('common.copy'),
                      onCopy: () => _copy(
                        area.googleMapsJavaScript,
                        t('coordinate.googleCircle'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: t('coordinate.appleCircle'),
                      value: area.appleMapKitSwift,
                      copyTooltip: t('common.copy'),
                      onCopy: () => _copy(
                        area.appleMapKitSwift,
                        t('coordinate.appleCircle'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: t('coordinate.googleRectangle'),
                      value: area.googleMapsRectangleJavaScript,
                      copyTooltip: t('common.copy'),
                      onCopy: () => _copy(
                        area.googleMapsRectangleJavaScript,
                        t('coordinate.googleRectangle'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultCard(
                      title: t('coordinate.appleRegion'),
                      value: area.appleMapKitRegionSwift,
                      copyTooltip: t('common.copy'),
                      onCopy: () => _copy(
                        area.appleMapKitRegionSwift,
                        t('coordinate.appleRegion'),
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
                ],
                const SizedBox(height: 28),
                _SectionTitle(title: t('coordinate.manualBox'), icon: Icons.crop_free_outlined),
                const SizedBox(height: 8),
                Text(t('coordinate.manualBoxSubtitle'), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(t('coordinate.boxCenterRadius'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _boxCenterLatitude,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxCenterLatitude'), border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _boxCenterLongitude,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxCenterLongitude'), border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _boxRadiusMeters,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t('coordinate.boxRadius'), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _generateManualBox,
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(t('coordinate.boxGenerate')),
                ),
                const SizedBox(height: 16),
                Text(t('coordinate.boxManualEdges'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _boxSouth,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxSouth'), border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _boxNorth,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxNorth'), border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _boxWest,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxWest'), border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _boxEast,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: t('coordinate.boxEast'), border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _validateManualBox,
                  icon: const Icon(Icons.crop_free),
                  label: Text(t('coordinate.boxValidate')),
                ),
                if (_manualBoxError != null) ...[
                  const SizedBox(height: 12),
                  Text(_manualBoxError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_manualBox != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    display.text(
                      'coordinate.boxCenter',
                      arguments: {
                        'lat': _manualBox!.centerLatitude.toStringAsFixed(6),
                        'lon': _manualBox!.centerLongitude.toStringAsFixed(6),
                      },
                    ),
                  ),
                  Text(
                    display.text(
                      'coordinate.boxSpan',
                      arguments: {
                        'lat': _manualBox!.latitudeSpan.toStringAsFixed(6),
                        'lon': _manualBox!.longitudeSpan.toStringAsFixed(6),
                      },
                    ),
                  ),
                  if (_manualBox!.wrapsAntimeridian) ...[
                    const SizedBox(height: 8),
                    Text(t('coordinate.boxAntimeridian')),
                  ],
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'South / West / North / East',
                    value: _manualBox!.labeledText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(_manualBox!.labeledText, 'South / West / North / East'),
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'BBox [west, south, east, north]',
                    value: _manualBox!.bboxText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(_manualBox!.bboxText, 'BBox'),
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'JSON',
                    value: _manualBox!.jsonText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(_manualBox!.jsonText, 'JSON'),
                  ),
                ],

                Text(t('coordinate.disclaimer'), style: Theme.of(context).textTheme.bodySmall),
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

class _MapLinkCard extends StatelessWidget {
  const _MapLinkCard({
    required this.title,
    required this.uri,
    required this.openLabel,
    required this.copyTooltip,
    required this.onOpen,
    required this.onCopy,
  });

  final String title;
  final Uri uri;
  final String openLabel;
  final String copyTooltip;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            SelectableText(uri.toString()),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: copyTooltip,
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(openLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
