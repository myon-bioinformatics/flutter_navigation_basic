import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/clipboard/base64_image_bridge.dart';
import '../../../shared/display/display_scope.dart';
import '../domain/normalized_rect.dart';
import 'photo_rect_canvas.dart';
import 'pick_local_image_bytes.dart';

class PhotoStudioPage extends StatefulWidget {
  const PhotoStudioPage({
    super.key,
    this.imageBytesPicker,
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

  @override
  State<PhotoStudioPage> createState() => _PhotoStudioPageState();
}

class _PhotoStudioPageState extends State<PhotoStudioPage> {
  Uint8List? _imageBytes;
  NormalizedRect _rect = NormalizedRect.initial;
  String? _status;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DisplayScope.of(context).text('photoStudio.copied'))),
    );
  }

  Future<void> _setImage(Uint8List rawBytes) async {
    final display = DisplayScope.of(context);
    try {
      final validated = await decodeRasterImageBytes(rawBytes);
      if (!mounted) return;
      if (validated == null) {
        setState(() => _status = display.text('photoStudio.imageError'));
        return;
      }
      final compact = await Base64ImageBridge.downscaleToPng(validated);
      if (!mounted) return;
      setState(() {
        _imageBytes = compact.bytes;
        _status = display.text(
          'photoStudio.imageLoaded',
          arguments: {'bytes': compact.bytes.length},
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = display.text('photoStudio.imageError'));
    }
  }

  Future<void> _pickImage() async {
    final picker = widget.imageBytesPicker ?? pickLocalImageBytes;
    final bytes = await picker();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      if (!kIsWeb && widget.imageBytesPicker == null) {
        setState(
          () => _status =
              DisplayScope.of(context).text('photoStudio.pickImageUnavailable'),
        );
      }
      return;
    }
    await _setImage(bytes);
  }

  Future<void> _pasteBase64() async {
    final display = DisplayScope.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      setState(() => _status = display.text('photoStudio.noBase64Image'));
      return;
    }
    try {
      final payload = Base64ImageBridge.decodeText(text);
      await _setImage(payload.bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = display.text('photoStudio.imageError'));
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _status = DisplayScope.of(context).text('photoStudio.imageCleared');
    });
  }

  void _resetRect() {
    setState(() => _rect = NormalizedRect.initial);
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key) => display.text(key);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('photoStudio.title')),
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
                  t('photoStudio.subtitle'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                _Section(
                  title: t('photoStudio.studio'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t('photoStudio.studioSubtitle'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('photoStudio.studioHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      PhotoRectCanvas(
                        rect: _rect,
                        imageBytes: _imageBytes,
                        onRectChanged: (rect) => setState(() => _rect = rect),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(t('photoStudio.pickImage')),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _pasteBase64,
                            icon: const Icon(Icons.content_paste),
                            label: Text(t('photoStudio.pasteBase64Image')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _imageBytes == null ? null : _clearImage,
                            icon: const Icon(Icons.hide_image_outlined),
                            label: Text(t('photoStudio.clearImage')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetRect,
                            icon: const Icon(Icons.crop_square_outlined),
                            label: Text(t('photoStudio.resetRect')),
                          ),
                        ],
                      ),
                      if (_status != null) ...[
                        const SizedBox(height: 8),
                        Text(_status!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      _CopyCard(
                        title: t('photoStudio.rectLabel'),
                        value: _rect.labeledText,
                        copyTooltip: t('common.copy'),
                        onCopy: () => _copy(_rect.csvText),
                      ),
                    ],
                  ),
                ),
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
