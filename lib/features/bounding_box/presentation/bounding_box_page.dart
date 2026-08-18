import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/display/display_scope.dart';
import '../domain/bounding_box.dart';

class BoundingBoxPage extends StatefulWidget {
  const BoundingBoxPage({super.key});

  @override
  State<BoundingBoxPage> createState() => _BoundingBoxPageState();
}

class _BoundingBoxPageState extends State<BoundingBoxPage> {
  final _south = TextEditingController(text: '35.676746');
  final _west = TextEditingController(text: '139.756060');
  final _north = TextEditingController(text: '35.685726');
  final _east = TextEditingController(text: '139.778190');
  final _centerLatitude = TextEditingController(text: '35.681236');
  final _centerLongitude = TextEditingController(text: '139.767125');
  final _radiusMeters = TextEditingController(text: '1000');

  BoundingBox? _box;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildFromBounds();
  }

  @override
  void dispose() {
    _south.dispose();
    _west.dispose();
    _north.dispose();
    _east.dispose();
    _centerLatitude.dispose();
    _centerLongitude.dispose();
    _radiusMeters.dispose();
    super.dispose();
  }

  void _buildFromBounds() {
    try {
      final box = BoundingBox.fromBounds(
        south: _south.text,
        west: _west.text,
        north: _north.text,
        east: _east.text,
      );
      setState(() {
        _box = box;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _box = null;
        _error = error.message.toString();
      });
    }
  }

  void _buildFromCenterRadius() {
    try {
      final latitude = double.parse(_centerLatitude.text.trim());
      final longitude = double.parse(_centerLongitude.text.trim());
      final radius = double.parse(_radiusMeters.text.trim());
      final box = BoundingBox.fromCenterRadius(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
      _south.text = box.south.toStringAsFixed(6);
      _west.text = box.west.toStringAsFixed(6);
      _north.text = box.north.toStringAsFixed(6);
      _east.text = box.east.toStringAsFixed(6);
      setState(() {
        _box = box;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _box = null;
        _error = error.message.toString();
      });
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DisplayScope.of(context).text('boundingBox.copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    final box = _box;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('boundingBox.title')),
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
                Text(t('boundingBox.subtitle'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                _Section(
                  title: t('boundingBox.centerRadius'),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _NumberField(controller: _centerLatitude, label: t('boundingBox.centerLatitude'))),
                          const SizedBox(width: 12),
                          Expanded(child: _NumberField(controller: _centerLongitude, label: t('boundingBox.centerLongitude'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NumberField(controller: _radiusMeters, label: t('boundingBox.radius')),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _buildFromCenterRadius,
                        icon: const Icon(Icons.center_focus_strong),
                        label: Text(t('boundingBox.generate')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: t('boundingBox.manual'),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _NumberField(controller: _south, label: t('boundingBox.south'))),
                          const SizedBox(width: 12),
                          Expanded(child: _NumberField(controller: _north, label: t('boundingBox.north'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _NumberField(controller: _west, label: t('boundingBox.west'))),
                          const SizedBox(width: 12),
                          Expanded(child: _NumberField(controller: _east, label: t('boundingBox.east'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _buildFromBounds,
                        icon: const Icon(Icons.crop_free),
                        label: Text(t('boundingBox.validate')),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (box != null) ...[
                  const SizedBox(height: 20),
                  Text(display.text('boundingBox.center', arguments: {
                    'lat': box.centerLatitude.toStringAsFixed(6),
                    'lon': box.centerLongitude.toStringAsFixed(6),
                  })),
                  Text(display.text('boundingBox.span', arguments: {
                    'lat': box.latitudeSpan.toStringAsFixed(6),
                    'lon': box.longitudeSpan.toStringAsFixed(6),
                  })),
                  if (box.wrapsAntimeridian)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(t('boundingBox.antimeridian')),
                    ),
                  const SizedBox(height: 12),
                  _CopyCard(title: 'South / West / North / East', value: box.labeledText, copyTooltip: t('common.copy'), onCopy: () => _copy(box.labeledText)),
                  const SizedBox(height: 12),
                  _CopyCard(title: 'BBox [west, south, east, north]', value: box.bboxText, copyTooltip: t('common.copy'), onCopy: () => _copy(box.bboxText)),
                  const SizedBox(height: 12),
                  _CopyCard(title: 'JSON', value: box.jsonText, copyTooltip: t('common.copy'), onCopy: () => _copy(box.jsonText)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({required this.title, required this.value, required this.copyTooltip, required this.onCopy});
  final String title;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          subtitle: SelectableText(value),
          trailing: IconButton(tooltip: copyTooltip, onPressed: onCopy, icon: const Icon(Icons.copy)),
        ),
      );
}
