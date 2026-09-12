import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/clipboard/base64_image_bridge.dart';
import '../../../shared/display/display_scope.dart';
import '../domain/emoji_stamp.dart';
import '../domain/photo_studio_test_probe.dart';
import '../domain/normalized_rect.dart';
import '../domain/studio_frame_style.dart';
import '../domain/studio_geometry.dart';
import 'compose_studio_image.dart';
import 'photo_rect_canvas.dart';
import 'pick_local_image_bytes.dart';
import 'save_image_bytes.dart';

typedef StudioImageSaver = Future<bool> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
});

class PhotoStudioPage extends StatefulWidget {
  const PhotoStudioPage({
    super.key,
    this.imageBytesPicker,
    this.imageSaver,
    this.onTestProbe,
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

  /// Optional override for save/download (tests inject a fake saver).
  final StudioImageSaver? imageSaver;

  /// Optional probe for widget tests (coords, undo depth, shared image refs).
  final ValueChanged<PhotoStudioTestProbe>? onTestProbe;

  @override
  State<PhotoStudioPage> createState() => _PhotoStudioPageState();
}

class _PhotoStudioPageState extends State<PhotoStudioPage> {
  static const _emojiPalette = <String>[
    '⭐',
    '❤️',
    '😊',
    '🔥',
    '📷',
    '🌸',
    '✨',
    '🍀',
  ];

  /// Fallback until the first canvas layout reports its size.
  static const _fallbackCanvasSize = Size(760, 280);

  /// Soft cap for undo history (oldest entries are dropped first).
  static const _maxUndoHistory = 20;

  Uint8List? _imageBytes;
  NormalizedRect _rect = NormalizedRect.initial;
  StudioFrameShape _shape = StudioFrameShape.rectangle;
  int _strokeArgb = StudioFrameColors.purple;
  List<EmojiStamp> _stamps = const [];
  String? _selectedEmojiStampId;
  String? _pendingEmoji;
  double _stampScale = 1;
  Size _canvasSize = _fallbackCanvasSize;
  String? _status;
  final List<PhotoStudioSnapshot> _undoHistory = <PhotoStudioSnapshot>[];

  PhotoStudioSnapshot _captureSnapshot() => PhotoStudioSnapshot(
        // Share the same Uint8List across snapshots; never deep-copy rasters.
        imageBytes: _imageBytes,
        rectLeft: _rect.left,
        rectTop: _rect.top,
        rectRight: _rect.right,
        rectBottom: _rect.bottom,
        shapeName: _shape.name,
        strokeArgb: _strokeArgb,
        stamps: List<EmojiStamp>.from(_stamps),
        selectedEmojiStampId: _selectedEmojiStampId,
        stampScale: _stampScale,
      );

  bool _matchesSnapshot(PhotoStudioSnapshot snap) {
    if (!identical(snap.imageBytes, _imageBytes)) return false;
    if (snap.rectLeft != _rect.left ||
        snap.rectTop != _rect.top ||
        snap.rectRight != _rect.right ||
        snap.rectBottom != _rect.bottom) {
      return false;
    }
    if (snap.shapeName != _shape.name) return false;
    if (snap.strokeArgb != _strokeArgb) return false;
    if (snap.selectedEmojiStampId != _selectedEmojiStampId) return false;
    if (snap.stampScale != _stampScale) return false;
    if (snap.stamps.length != _stamps.length) return false;
    for (var i = 0; i < snap.stamps.length; i++) {
      if (snap.stamps[i] != _stamps[i]) return false;
    }
    return true;
  }

  void _emitTestProbe() {
    final probe = widget.onTestProbe;
    if (probe == null) return;
    probe(
      PhotoStudioTestProbe(
        stamps: List<EmojiStamp>.from(_stamps),
        undoDepth: _undoHistory.length,
        imageBytes: _imageBytes,
        undoImageByteRefs: [
          for (final snap in _undoHistory) snap.imageBytes,
        ],
        rectLeft: _rect.left,
        rectTop: _rect.top,
        rectRight: _rect.right,
        rectBottom: _rect.bottom,
        shapeName: _shape.name,
        strokeArgb: _strokeArgb,
        stampScale: _stampScale,
      ),
    );
  }

  void _pushUndo() {
    _undoHistory.add(_captureSnapshot());
    if (_undoHistory.length > _maxUndoHistory) {
      _undoHistory.removeAt(0);
    }
    _emitTestProbe();
  }

  void _discardLastUndoIfUnchanged() {
    if (_undoHistory.isEmpty) return;
    if (!_matchesSnapshot(_undoHistory.last)) return;
    _undoHistory.removeLast();
    _emitTestProbe();
  }

  void _undoOnce() {
    if (_undoHistory.isEmpty) return;
    final snap = _undoHistory.removeLast();
    setState(() {
      // Restore the shared reference; do not allocate a new Uint8List copy.
      _imageBytes = snap.imageBytes;
      _rect = NormalizedRect(
        left: snap.rectLeft,
        top: snap.rectTop,
        right: snap.rectRight,
        bottom: snap.rectBottom,
      );
      _shape = StudioFrameShape.values.byName(snap.shapeName);
      _strokeArgb = snap.strokeArgb;
      _stamps = List<EmojiStamp>.from(snap.stamps);
      _selectedEmojiStampId = snap.selectedEmojiStampId;
      _stampScale = snap.stampScale;
      _status = DisplayScope.of(context).text('photoStudio.undoDone');
    });
    _emitTestProbe();
  }

  bool get _canUndo => _undoHistory.isNotEmpty;

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
      _pushUndo();
      setState(() {
        _imageBytes = compact.bytes;
        _status = display.text(
          'photoStudio.imageLoaded',
          arguments: {'bytes': compact.bytes.length},
        );
      });
      _emitTestProbe();
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
          () => _status = DisplayScope.of(context)
              .text('photoStudio.pickImageUnavailable'),
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

  Future<void> _copyImageBase64() async {
    final display = DisplayScope.of(context);
    final bytes = _imageBytes;
    if (bytes == null) {
      setState(() => _status = display.text('photoStudio.noImageToCopy'));
      return;
    }
    final payload = Base64ImagePayload(bytes: bytes, mimeType: 'image/png');
    await _copy(payload.dataUrl);
    if (!mounted) return;
    setState(() => _status = display.text('photoStudio.imageCopied'));
  }

  void _clearImage() {
    _pushUndo();
    setState(() {
      _imageBytes = null;
      _status = DisplayScope.of(context).text('photoStudio.imageCleared');
    });
    _discardLastUndoIfUnchanged();
    _emitTestProbe();
  }

  void _resetRect() {
    _pushUndo();
    setState(() => _rect = NormalizedRect.initial);
    _discardLastUndoIfUnchanged();
    _emitTestProbe();
  }

  Future<void> _savePng() async {
    final display = DisplayScope.of(context);
    try {
      final logicalSize = _canvasSize.width > 0 && _canvasSize.height > 0
          ? _canvasSize
          : _fallbackCanvasSize;
      final png = await composeStudioPng(
        logicalSize: logicalSize,
        rect: _rect,
        shape: _shape,
        strokeColor: Color(_strokeArgb),
        stamps: _stamps,
        imageBytes: _imageBytes,
      );
      final saver = widget.imageSaver ?? saveImageBytes;
      final ok = await saver(
        bytes: png,
        fileName: kStudioExportFileName,
        mimeType: kStudioExportMimeType,
      );
      if (!mounted) return;
      setState(() {
        _status = display.text(
          ok ? 'photoStudio.saveDone' : 'photoStudio.saveUnavailable',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = display.text('photoStudio.saveError'));
    }
  }

  void _onRectChanged(NormalizedRect rect) {
    setState(() => _rect = rect);
    _emitTestProbe();
  }

  void _onStampsChanged(List<EmojiStamp> stamps) {
    setState(() {
      final previousIds = _stamps.map((s) => s.emojiStampId).toSet();
      _stamps = stamps;
      if (_pendingEmoji != null) {
        _pendingEmoji = null;
      }
      // A newly placed stamp should become selected with its own scale (1.0).
      final added = stamps
          .where((s) => !previousIds.contains(s.emojiStampId))
          .toList();
      if (added.isNotEmpty) {
        final newest = added.last;
        _selectedEmojiStampId = newest.emojiStampId;
        _stampScale = newest.scale;
        return;
      }
      final selectedEmojiStampId = _selectedEmojiStampId;
      if (selectedEmojiStampId != null) {
        final match =
            stamps.where((s) => s.emojiStampId == selectedEmojiStampId);
        if (match.isNotEmpty) {
          _stampScale = match.first.scale;
        }
      }
    });
    _emitTestProbe();
  }

  void _onSelectedEmojiStampIdChanged(String? emojiStampId) {
    setState(() {
      _selectedEmojiStampId = emojiStampId;
      if (emojiStampId == null) return;
      final match = _stamps.where((s) => s.emojiStampId == emojiStampId);
      if (match.isNotEmpty) {
        _stampScale = match.first.scale;
      }
    });
    _emitTestProbe();
  }

  void _applyStampScale(double scale) {
    setState(() {
      _stampScale = scale;
      final selectedEmojiStampId = _selectedEmojiStampId;
      if (selectedEmojiStampId == null) return;
      _stamps = [
        for (final stamp in _stamps)
          if (stamp.emojiStampId == selectedEmojiStampId)
            stamp.copyWith(scale: scale)
          else
            stamp,
      ];
    });
    _emitTestProbe();
  }

  void _onCanvasSizeChanged(Size size) {
    if (size == _canvasSize) return;
    setState(() => _canvasSize = size);
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key, {Map<String, Object?> arguments = const {}}) =>
        display.text(key, arguments: arguments);
    final geometry = StudioGeometry.describe(_rect, _shape);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undoOnce,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undoOnce,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(t('photoStudio.title')),
            actions: [
              IconButton(
                tooltip: t('photoStudio.undo'),
                onPressed: _canUndo ? _undoOnce : null,
                icon: const Icon(Icons.undo),
              ),
              const DisplayLocalePicker(compact: true),
            ],
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
                            onRectChanged: _onRectChanged,
                            shape: _shape,
                            strokeColor: Color(_strokeArgb),
                            stamps: _stamps,
                            onStampsChanged: _onStampsChanged,
                            selectedEmojiStampId: _selectedEmojiStampId,
                            onSelectedEmojiStampIdChanged:
                                _onSelectedEmojiStampIdChanged,
                            pendingEmoji: _pendingEmoji,
                            onEditStart: _pushUndo,
                            onEditEnd: _discardLastUndoIfUnchanged,
                            onCanvasSizeChanged: _onCanvasSizeChanged,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.frameShape'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final shape in StudioFrameShape.values)
                                ChoiceChip(
                                  label:
                                      Text(t('photoStudio.shape.${shape.name}')),
                                  selected: _shape == shape,
                                  onSelected: (_) {
                                    if (_shape == shape) return;
                                    _pushUndo();
                                    setState(() => _shape = shape);
                                    _emitTestProbe();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.frameColor'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final argb in StudioFrameColors.presets)
                                GestureDetector(
                                  onTap: () {
                                    if (_strokeArgb == argb) return;
                                    _pushUndo();
                                    setState(() => _strokeArgb = argb);
                                    _emitTestProbe();
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(argb),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _strokeArgb == argb
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                        width: _strokeArgb == argb ? 2.5 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.stamps'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final emoji in _emojiPalette)
                                ActionChip(
                                  label: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _pendingEmoji =
                                          _pendingEmoji == emoji ? null : emoji;
                                    });
                                  },
                                  backgroundColor: _pendingEmoji == emoji
                                      ? Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                      : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'photoStudio.stampScale',
                              arguments: {
                                'scale': _stampScale.toStringAsFixed(1),
                              },
                            ),
                          ),
                          Slider(
                            value: _stampScale.clamp(0.4, 3.0),
                            min: 0.4,
                            max: 3.0,
                            divisions: 26,
                            label: _stampScale.toStringAsFixed(1),
                            onChangeStart: (_) => _pushUndo(),
                            onChanged: _applyStampScale,
                            onChangeEnd: (_) => _discardLastUndoIfUnchanged(),
                          ),
                          const SizedBox(height: 8),
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
                              FilledButton.tonalIcon(
                                onPressed: _imageBytes == null
                                    ? null
                                    : _copyImageBase64,
                                icon: const Icon(Icons.copy_all_outlined),
                                label: Text(t('photoStudio.copyImage')),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _imageBytes == null ? null : _clearImage,
                                icon: const Icon(Icons.hide_image_outlined),
                                label: Text(t('photoStudio.clearImage')),
                              ),
                              OutlinedButton.icon(
                                onPressed: _resetRect,
                                icon: const Icon(Icons.crop_square_outlined),
                                label: Text(t('photoStudio.resetRect')),
                              ),
                              OutlinedButton.icon(
                                onPressed: _canUndo ? _undoOnce : null,
                                icon: const Icon(Icons.undo),
                                label: Text(t('photoStudio.undo')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.saveAs'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('photoStudio.savePngOnlyHint'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: _savePng,
                              icon: const Icon(Icons.download_outlined),
                              label: Text(t('photoStudio.saveFile')),
                            ),
                          ),
                          if (_status != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _status!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _CopyCard(
                            title: t('photoStudio.rectLabel'),
                            value: _rect.labeledText,
                            copyTooltip: t('common.copy'),
                            onCopy: () => _copy(_rect.csvText),
                          ),
                          const SizedBox(height: 8),
                          _CopyCard(
                            title: t('photoStudio.geometryLabel'),
                            value: geometry,
                            copyTooltip: t('common.copy'),
                            onCopy: () => _copy(geometry),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
