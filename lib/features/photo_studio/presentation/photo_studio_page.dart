import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/clipboard/base64_image_bridge.dart';
import '../../../shared/display/display_scope.dart';
import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/photo_studio_history.dart';
import '../domain/photo_studio_state.dart';
import '../domain/studio_document.dart';
import '../domain/studio_export_result.dart';
import '../domain/studio_frame_style.dart';
import '../domain/studio_geometry.dart';
import 'export_studio_png.dart';
import 'photo_rect_canvas.dart';
import 'pick_local_image_bytes.dart';

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
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

  /// Optional override for save/download (tests inject a fake saver).
  final StudioImageSaver? imageSaver;

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

  PhotoStudioState _studio = PhotoStudioState.initial();
  final PhotoStudioHistory _history = PhotoStudioHistory();
  String? _pendingEmoji;
  Size _canvasSize = _fallbackCanvasSize;
  String? _status;

  bool get _canUndo => _history.canUndo;

  void _beginUndoGesture() {
    _history.beginGesture(_studio);
  }

  void _endUndoGesture() {
    // Rebuild Undo controls; gesture commits often follow the last mutating
    // setState, when history was still empty and buttons were disabled.
    if (_history.endGesture(_studio)) {
      setState(() {});
    }
  }

  void _mutateWithUndo(PhotoStudioState Function(PhotoStudioState) transform) {
    final before = _studio;
    final after = transform(before);
    _history.recordChange(before, after);
    _studio = after;
  }

  void _setStateWithUndo(PhotoStudioState Function(PhotoStudioState) transform) {
    setState(() => _mutateWithUndo(transform));
  }

  void _undoOnce() {
    final snap = _history.undo();
    if (snap == null) return;
    setState(() {
      _studio = snap;
      _status = DisplayScope.of(context).text('photoStudio.undoDone');
    });
  }

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
        _mutateWithUndo(
          (s) => s.copyWith(imageBytes: compact.bytes),
        );
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
    final bytes = _studio.imageBytes;
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
    setState(() {
      _mutateWithUndo((s) => s.copyWith(imageBytes: null));
      _status = DisplayScope.of(context).text('photoStudio.imageCleared');
    });
  }

  void _resetRect() {
    _setStateWithUndo((s) => s.copyWith(rect: NormalizedRect.initial));
  }

  Future<void> _savePng() async {
    final display = DisplayScope.of(context);
    final logicalSize = _canvasSize.width > 0 && _canvasSize.height > 0
        ? _canvasSize
        : _fallbackCanvasSize;
    final result = await exportStudioPng(
      document: StudioDocument.fromState(
        _studio,
        logicalCanvasSize: logicalSize,
      ),
      saver: widget.imageSaver,
    );
    if (!mounted) return;
    final key = switch (result.outcome) {
      StudioExportOutcome.saved => 'photoStudio.saveDone',
      StudioExportOutcome.unavailable => 'photoStudio.saveUnavailable',
      StudioExportOutcome.failed => 'photoStudio.saveError',
    };
    setState(() => _status = display.text(key));
  }

  void _onRectChanged(NormalizedRect rect) {
    setState(() => _studio = _studio.copyWith(rect: rect));
  }

  void _onStampsChanged(List<EmojiStamp> stamps) {
    setState(() {
      final previousIds = _studio.stamps.map((s) => s.emojiStampId).toSet();
      var next = _studio.copyWith(stamps: stamps);
      if (_pendingEmoji != null) {
        _pendingEmoji = null;
      }
      // A newly placed stamp should become selected with its own scale (1.0).
      final added = stamps
          .where((s) => !previousIds.contains(s.emojiStampId))
          .toList();
      if (added.isNotEmpty) {
        final newest = added.last;
        next = next.copyWith(
          selectedEmojiStampId: newest.emojiStampId,
          stampScale: newest.scale,
        );
      } else {
        final selectedEmojiStampId = next.selectedEmojiStampId;
        if (selectedEmojiStampId != null) {
          final match =
              stamps.where((s) => s.emojiStampId == selectedEmojiStampId);
          if (match.isNotEmpty) {
            next = next.copyWith(stampScale: match.first.scale);
          }
        }
      }
      _studio = next;
    });
  }

  void _onSelectedEmojiStampIdChanged(String? emojiStampId) {
    setState(() {
      var next = _studio.copyWith(selectedEmojiStampId: emojiStampId);
      if (emojiStampId != null) {
        final match = next.stamps.where((s) => s.emojiStampId == emojiStampId);
        if (match.isNotEmpty) {
          next = next.copyWith(stampScale: match.first.scale);
        }
      }
      _studio = next;
    });
  }

  void _applyStampScale(double scale) {
    setState(() {
      final selectedEmojiStampId = _studio.selectedEmojiStampId;
      if (selectedEmojiStampId == null) {
        _studio = _studio.copyWith(stampScale: scale);
        return;
      }
      _studio = _studio.copyWith(
        stampScale: scale,
        stamps: [
          for (final stamp in _studio.stamps)
            if (stamp.emojiStampId == selectedEmojiStampId)
              stamp.copyWith(scale: scale)
            else
              stamp,
        ],
      );
    });
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
    final geometry = StudioGeometry.describe(_studio.rect, _studio.shape);

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
                            rect: _studio.rect,
                            imageBytes: _studio.imageBytes,
                            onRectChanged: _onRectChanged,
                            shape: _studio.shape,
                            strokeColor: Color(_studio.strokeArgb),
                            stamps: _studio.stamps,
                            onStampsChanged: _onStampsChanged,
                            selectedEmojiStampId: _studio.selectedEmojiStampId,
                            onSelectedEmojiStampIdChanged:
                                _onSelectedEmojiStampIdChanged,
                            pendingEmoji: _pendingEmoji,
                            onEditStart: _beginUndoGesture,
                            onEditEnd: _endUndoGesture,
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
                                  selected: _studio.shape == shape,
                                  onSelected: (_) {
                                    if (_studio.shape == shape) return;
                                    _setStateWithUndo(
                                      (s) => s.copyWith(shape: shape),
                                    );
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
                                    if (_studio.strokeArgb == argb) return;
                                    _setStateWithUndo(
                                      (s) => s.copyWith(strokeArgb: argb),
                                    );
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(argb),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _studio.strokeArgb == argb
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                        width: _studio.strokeArgb == argb
                                            ? 2.5
                                            : 1,
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
                                'scale':
                                    _studio.stampScale.toStringAsFixed(1),
                              },
                            ),
                          ),
                          Slider(
                            value: _studio.stampScale.clamp(0.4, 3.0),
                            min: 0.4,
                            max: 3.0,
                            divisions: 26,
                            label: _studio.stampScale.toStringAsFixed(1),
                            onChangeStart: (_) => _beginUndoGesture(),
                            onChanged: _applyStampScale,
                            onChangeEnd: (_) => _endUndoGesture(),
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
                                onPressed: _studio.imageBytes == null
                                    ? null
                                    : _copyImageBase64,
                                icon: const Icon(Icons.copy_all_outlined),
                                label: Text(t('photoStudio.copyImage')),
                              ),
                              OutlinedButton.icon(
                                onPressed: _studio.imageBytes == null
                                    ? null
                                    : _clearImage,
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
                            value: _studio.rect.labeledText,
                            copyTooltip: t('common.copy'),
                            onCopy: () => _copy(_studio.rect.csvText),
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
