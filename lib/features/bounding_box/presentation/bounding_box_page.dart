import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/clipboard/base64_image_bridge.dart';
import '../../../shared/display/display_scope.dart';
import '../domain/bounding_box.dart';
import '../domain/normalized_rect.dart';
import 'image_rect_overlay.dart';
import 'pick_local_image_bytes.dart';

class BoundingBoxPage extends StatefulWidget {
  const BoundingBoxPage({
    super.key,
    this.imageBytesPicker,
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

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
  Uint8List? _overlayImageBytes;
  NormalizedRect _overlayRect = NormalizedRect.initial;
  String? _overlayStatus;

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

  Future<void> _setOverlayImage(Uint8List rawBytes) async {
    final display = DisplayScope.of(context);
    try {
      final validated = await decodeRasterImageBytes(rawBytes);
      if (!mounted) return;
      if (validated == null) {
        setState(() => _overlayStatus = display.text('boundingBox.imageError'));
        return;
      }
      final compact = await Base64ImageBridge.downscaleToPng(validated);
      if (!mounted) return;
      setState(() {
        _overlayImageBytes = compact.bytes;
        _overlayStatus = display.text(
          'boundingBox.imageLoaded',
          arguments: {'bytes': compact.bytes.length},
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _overlayStatus = display.text('boundingBox.imageError'));
    }
  }

  Future<void> _pickOverlayImage() async {
    final picker = widget.imageBytesPicker ?? pickLocalImageBytes;
    final bytes = await picker();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      if (!kIsWeb && widget.imageBytesPicker == null) {
        setState(
          () => _overlayStatus =
              DisplayScope.of(context).text('boundingBox.pickImageUnavailable'),
        );
      }
      return;
    }
    await _setOverlayImage(bytes);
  }

  Future<void> _pasteOverlayBase64() async {
    final display = DisplayScope.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      setState(() => _overlayStatus = display.text('boundingBox.noBase64Image'));
      return;
    }
    try {
      final payload = Base64ImageBridge.decodeText(text);
      await _setOverlayImage(payload.bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _overlayStatus = display.text('boundingBox.imageError'));
    }
  }

  void _clearOverlayImage() {
    setState(() {
      _overlayImageBytes = null;
      _overlayStatus = DisplayScope.of(context).text('boundingBox.imageCleared');
    });
  }

  void _resetOverlayRect() {
    setState(() => _overlayRect = NormalizedRect.initial);
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
                Text(
                  t('boundingBox.subtitle'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                _Section(
                  title: t('boundingBox.imageOverlay'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t('boundingBox.imageOverlaySubtitle'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('boundingBox.overlayHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ImageRectOverlay(
                        rect: _overlayRect,
                        imageBytes: _overlayImageBytes,
                        onRectChanged: (rect) =>
                            setState(() => _overlayRect = rect),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _pickOverlayImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(t('boundingBox.pickImage')),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _pasteOverlayBase64,
                            icon: const Icon(Icons.content_paste),
                            label: Text(t('boundingBox.pasteBase64Image')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _overlayImageBytes == null
                                ? null
                                : _clearOverlayImage,
                            icon: const Icon(Icons.hide_image_outlined),
                            label: Text(t('boundingBox.clearImage')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetOverlayRect,
                            icon: const Icon(Icons.crop_square_outlined),
                            label: Text(t('boundingBox.resetRect')),
                          ),
                        ],
                      ),
                      if (_overlayStatus != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _overlayStatus!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _CopyCard(
                        title: t('boundingBox.rectLabel'),
                        value: _overlayRect.labeledText,
                        copyTooltip: t('common.copy'),
                        onCopy: () => _copy(_overlayRect.csvText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: t('boundingBox.centerRadius'),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _centerLatitude,
                              label: t('boundingBox.centerLatitude'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _centerLongitude,
                              label: t('boundingBox.centerLongitude'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        controller: _radiusMeters,
                        label: t('boundingBox.radius'),
                      ),
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
                          Expanded(
                            child: _NumberField(
                              controller: _south,
                              label: t('boundingBox.south'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _north,
                              label: t('boundingBox.north'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _west,
                              label: t('boundingBox.west'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _east,
                              label: t('boundingBox.east'),
                            ),
                          ),
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
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (box != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    display.text(
                      'boundingBox.center',
                      arguments: {
                        'lat': box.centerLatitude.toStringAsFixed(6),
                        'lon': box.centerLongitude.toStringAsFixed(6),
                      },
                    ),
                  ),
                  Text(
                    display.text(
                      'boundingBox.span',
                      arguments: {
                        'lat': box.latitudeSpan.toStringAsFixed(6),
                        'lon': box.longitudeSpan.toStringAsFixed(6),
                      },
                    ),
                  ),
                  if (box.wrapsAntimeridian)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(t('boundingBox.antimeridian')),
                    ),
                  const SizedBox(height: 12),
                  _CopyCard(
                    title: 'South / West / North / East',
                    value: box.labeledText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(box.labeledText),
                  ),
                  const SizedBox(height: 12),
                  _CopyCard(
                    title: 'BBox [west, south, east, north]',
                    value: box.bboxText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(box.bboxText),
                  ),
                  const SizedBox(height: 12),
                  _CopyCard(
                    title: 'JSON',
                    value: box.jsonText,
                    copyTooltip: t('common.copy'),
                    onCopy: () => _copy(box.jsonText),
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
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({
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
