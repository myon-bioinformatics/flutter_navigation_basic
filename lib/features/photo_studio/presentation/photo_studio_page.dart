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
import '../domain/studio_frame.dart';
import '../domain/studio_frame_style.dart';
import '../domain/studio_canvas_mode.dart';
import '../domain/studio_geometry.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/tool_door_selector.dart';
import 'browser_image_decode_adapter.dart';
import 'export_studio_png.dart';
import 'photo_rect_canvas.dart';
import 'pick_local_image_bytes.dart';
import 'read_web_clipboard_image_bytes.dart';
import 'studio_image_loader.dart';

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
    this.clipboardImageReader,
    this.imageDecodeAdapter,
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

  /// Optional override for save/download (tests inject a fake saver).
  final StudioImageSaver? imageSaver;

  /// Optional override for reading binary clipboard images (tests / web).
  final Future<Uint8List?> Function()? clipboardImageReader;

  /// Optional decode adapter (tests inject fakes; web defaults to browser bridge).
  final StudioImageDecodeAdapter? imageDecodeAdapter;

  @override
  State<PhotoStudioPage> createState() => _PhotoStudioPageState();
}

class _PhotoStudioPageState extends State<PhotoStudioPage> {
  /// Tiny optional shortcuts — not a hard stamp library.
  static const _emojiShortcuts = <String>[
    '⭐',
    '❤️',
    '😊',
    '🔥',
    '📷',
    '🌸',
    '✨',
    '🍀',
  ];

  static const _maxImageBytes = 4 * 1024 * 1024;
  static const _maxImageClipboardChars = _maxImageBytes;

  /// Fallback until the first canvas layout reports its size.
  static const _fallbackCanvasSize = Size(760, 280);

  PhotoStudioState _studio = PhotoStudioState.initial();
  final PhotoStudioHistory _history = PhotoStudioHistory();
  final TextEditingController _stampController = TextEditingController();
  String? _pendingEmoji;
  Size _canvasSize = _fallbackCanvasSize;
  String? _status;
  bool _dirty = false;
  bool _decoding = false;
  StudioCanvasMode _canvasMode = StudioCanvasMode.frame;

  bool get _canUndo => _history.canUndo;
  bool get _canRedo => _history.canRedo;

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  void _beginUndoGesture() {
    _history.beginGesture(_studio);
  }

  void _endUndoGesture() {
    if (_history.endGesture(_studio)) {
      setState(() => _dirty = true);
    }
  }

  void _mutateWithUndo(PhotoStudioState Function(PhotoStudioState) transform) {
    final before = _studio;
    final after = transform(before);
    if (_history.recordChange(before, after)) {
      _dirty = true;
    }
    _studio = after;
  }

  void _setStateWithUndo(PhotoStudioState Function(PhotoStudioState) transform) {
    setState(() => _mutateWithUndo(transform));
  }

  void _undoOnce() {
    final snap = _history.undo(_studio);
    if (snap == null) return;
    setState(() {
      _studio = snap;
      _dirty = true;
      _status = DisplayScope.of(context).text('photoStudio.undoDone');
    });
  }

  void _redoOnce() {
    final snap = _history.redo(_studio);
    if (snap == null) return;
    setState(() {
      _studio = snap;
      _dirty = true;
      _status = DisplayScope.of(context).text('photoStudio.redoDone');
    });
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) return true;
    final display = DisplayScope.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(display.text('photoStudio.leaveTitle')),
        content: Text(display.text('photoStudio.leaveBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(display.text('photoStudio.leaveStay')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(display.text('photoStudio.leaveDiscard')),
          ),
        ],
      ),
    );
    return result ?? false;
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
    if (rawBytes.lengthInBytes > _maxImageBytes) {
      setState(() => _status = display.text('photoStudio.imageError'));
      return;
    }
    setState(() {
      _decoding = true;
      _status = display.text('photoStudio.decoding');
    });
    try {
      final adapter = widget.imageDecodeAdapter ??
          (kIsWeb ? browserImageDecodeAdapter : null);
      final validated = await loadStudioImageBytes(
        rawBytes,
        nativeDecodeAdapter: adapter,
      );
      if (!mounted) return;
      if (validated == null) {
        setState(() {
          _decoding = false;
          _status = display.text('photoStudio.imageUnsupported');
        });
        return;
      }
      final compact = await Base64ImageBridge.downscaleToPng(validated);
      if (!mounted) return;
      // Require a non-empty PNG payload before treating load as success.
      if (compact.bytes.isEmpty) {
        setState(() {
          _decoding = false;
          _status = display.text('photoStudio.imageError');
        });
        return;
      }
      setState(() {
        _decoding = false;
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
      setState(() {
        _decoding = false;
        _status = display.text('photoStudio.imageError');
      });
    }
  }

  void _setCanvasMode(StudioCanvasMode mode) {
    setState(() {
      _canvasMode = mode;
      // Mode only gates canvas create/place/move/resize. Do not mutate
      // draftShape here — that belongs in undoable shape-chip actions.
      if (mode != StudioCanvasMode.stamp) {
        _pendingEmoji = null;
      }
    });
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

  bool _looksLikeRawBase64(String value) {
    if (value.length < 80 ||
        value.length > _maxImageClipboardChars ||
        value.length % 4 != 0) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(value);
  }

  Future<void> _pasteImage() async {
    final display = DisplayScope.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      final imageCandidate =
          text.startsWith('data:image/') || _looksLikeRawBase64(text);
      // Oversized data:image / base64 text must not bypass the size cap.
      if (imageCandidate && text.length <= _maxImageClipboardChars) {
        try {
          final payload = Base64ImageBridge.decodeText(text);
          await _setImage(payload.bytes);
          return;
        } catch (_) {
          // Fall through to binary clipboard / clear error.
        }
      }
    }

    final customReader = widget.clipboardImageReader;
    final bytes = customReader != null
        ? await customReader()
        : await readWebClipboardImageBytes(maxBytes: _maxImageBytes);
    if (!mounted) return;
    if (bytes != null && bytes.isNotEmpty) {
      await _setImage(bytes);
      return;
    }
    setState(() => _status = display.text('photoStudio.noClipboardImage'));
  }

  void _handleInsertedContent(KeyboardInsertedContent content) {
    final bytes = content.data;
    if (bytes == null ||
        bytes.isEmpty ||
        bytes.lengthInBytes > _maxImageBytes ||
        !content.mimeType.startsWith('image/')) {
      return;
    }
    _setImage(bytes);
  }

  Future<void> _copyImage() async {
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

  void _resetSelectedFrame() {
    final selected = _studio.selectedFrame;
    if (selected == null) return;
    _setStateWithUndo(
      (s) => s.copyWith(
        frames: [
          for (final frame in s.frames)
            if (frame.studioFrameId == selected.studioFrameId)
              frame.copyWith(rect: NormalizedRect.initial)
            else
              frame,
        ],
      ),
    );
  }

  void _deleteSelectedFrame() {
    final studioFrameId = _studio.selectedStudioFrameId;
    if (studioFrameId == null) return;
    _setStateWithUndo(
      (s) => s.copyWith(
        frames: [
          for (final frame in s.frames)
            if (frame.studioFrameId != studioFrameId) frame,
        ],
        selectedStudioFrameId: null,
      ),
    );
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
    setState(() {
      _status = display.text(key);
      if (result.outcome == StudioExportOutcome.saved) {
        _dirty = false;
      }
    });
    if (result.outcome == StudioExportOutcome.saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(display.text('photoStudio.saveSnack'))),
      );
    }
  }

  void _onFramesChanged(List<StudioFrame> frames) {
    setState(() {
      var next = _studio.copyWith(frames: frames);
      final selectedId = next.selectedStudioFrameId;
      if (selectedId != null &&
          !frames.any((f) => f.studioFrameId == selectedId)) {
        next = next.copyWith(selectedStudioFrameId: null);
      }
      _studio = next;
    });
  }

  void _onSelectedStudioFrameIdChanged(String? studioFrameId) {
    setState(() {
      _studio = _studio.copyWith(selectedStudioFrameId: studioFrameId);
    });
  }

  void _onStampsChanged(List<EmojiStamp> stamps) {
    setState(() {
      final previousIds = _studio.stamps.map((s) => s.emojiStampId).toSet();
      var next = _studio.copyWith(stamps: stamps);
      if (_pendingEmoji != null) {
        _pendingEmoji = null;
      }
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

  void _armCustomStamp() {
    final text = _stampController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (_pendingEmoji == text) {
        _pendingEmoji = null;
        return;
      }
      _pendingEmoji = text;
      _canvasMode = StudioCanvasMode.stamp;
    });
  }

  void _togglePendingStamp(String stamp) {
    setState(() {
      if (_pendingEmoji == stamp) {
        _pendingEmoji = null;
        return;
      }
      _pendingEmoji = stamp;
      _stampController.text = stamp;
      _canvasMode = StudioCanvasMode.stamp;
    });
  }

  void _applyStrokeColor(int argb) {
    if (_studio.draftStrokeArgb == argb &&
        (_studio.selectedFrame == null ||
            _studio.selectedFrame!.strokeArgb == argb)) {
      return;
    }
    _setStateWithUndo((s) {
      final selectedId = s.selectedStudioFrameId;
      return s.copyWith(
        draftStrokeArgb: argb,
        frames: selectedId == null
            ? null
            : [
                for (final frame in s.frames)
                  if (frame.studioFrameId == selectedId)
                    frame.copyWith(strokeArgb: argb)
                  else
                    frame,
              ],
      );
    });
  }

  void _setDraftShape(StudioFrameShape? shape) {
    setState(() {
      _canvasMode = StudioCanvasMode.frame;
      _pendingEmoji = null;
      if (_studio.draftShape != shape) {
        _mutateWithUndo((s) => s.copyWith(draftShape: shape));
      }
    });
  }

  void _onCanvasSizeChanged(Size size) {
    if (size == _canvasSize) return;
    setState(() => _canvasSize = size);
  }

  String _frameChipLabel(StudioFrame frame, int index) {
    final shapeKey = 'photoStudio.shape.${frame.shape.name}';
    final shape = DisplayScope.of(context).text(shapeKey);
    return '$shape ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    String t(String key, {Map<String, Object?> arguments = const {}}) =>
        display.text(key, arguments: arguments);
    final selected = _studio.selectedFrame;
    final geometry = selected == null
        ? t('photoStudio.noFrameSelected')
        : StudioGeometry.describe(selected.rect, selected.shape);
    final rectText =
        selected?.rect.labeledText ?? t('photoStudio.noFrameSelected');

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscardIfDirty();
        if (!mounted || !leave) return;
        setState(() => _dirty = false);
        Navigator.of(context).maybePop();
      },
      child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undoOnce,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undoOnce,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _redoOnce,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _redoOnce,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Flexible(child: Text(t('photoStudio.title'))),
                if (_dirty) ...[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(t('photoStudio.draftBadge')),
                    padding: EdgeInsets.zero,
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            actions: [
              const SizedBox(width: 8),
              IconButton(
                tooltip: t('photoStudio.undo'),
                onPressed: _canUndo ? _undoOnce : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: t('photoStudio.redo'),
                onPressed: _canRedo ? _redoOnce : null,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                tooltip: t('photoStudio.saveFile'),
                onPressed: _decoding ? null : _savePng,
                icon: const Icon(Icons.save_outlined),
              ),
              const SizedBox(width: 8),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              PhotoRectCanvas(
                                frames: _studio.frames,
                                onFramesChanged: _onFramesChanged,
                                selectedStudioFrameId:
                                    _studio.selectedStudioFrameId,
                                onSelectedStudioFrameIdChanged:
                                    _onSelectedStudioFrameIdChanged,
                                draftShape: _canvasMode == StudioCanvasMode.frame
                                    ? (_studio.draftShape ??
                                        StudioFrameShape.rectangle)
                                    : null,
                                draftStrokeArgb: _studio.draftStrokeArgb,
                                imageBytes: _studio.imageBytes,
                                stamps: _studio.stamps,
                                onStampsChanged: _onStampsChanged,
                                selectedEmojiStampId:
                                    _studio.selectedEmojiStampId,
                                onSelectedEmojiStampIdChanged:
                                    _onSelectedEmojiStampIdChanged,
                                pendingEmoji: _canvasMode == StudioCanvasMode.stamp
                                    ? _pendingEmoji
                                    : null,
                                interactionMode: _canvasMode,
                                onEditStart: _beginUndoGesture,
                                onEditEnd: _endUndoGesture,
                                onCanvasSizeChanged: _onCanvasSizeChanged,
                              ),
                              if (_decoding)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.72),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 12),
                                        Text(t('photoStudio.decoding')),
                                      ],
                                    ),
                                  ),
                                )
                              else if (_studio.imageBytes == null &&
                                  _studio.frames.isEmpty &&
                                  _studio.stamps.isEmpty &&
                                  _pendingEmoji == null &&
                                  _studio.draftShape == null)
                                // Initial empty import affordance. Hide once a
                                // shape/stamp tool is armed or layers exist so
                                // frames-without-photo editing still works.
                                Positioned.fill(
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.92),
                                    child: InkWell(
                                      onTap: _pickImage,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 42,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            t('photoStudio.emptyTitle'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Text(
                                              t('photoStudio.emptyBody'),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.frameTool'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in <(StudioCanvasMode, String, IconData)>[
                                (StudioCanvasMode.frame, 'photoStudio.toolFrame', Icons.crop_free),
                                (StudioCanvasMode.stamp, 'photoStudio.toolStamp', Icons.emoji_emotions_outlined),
                                (StudioCanvasMode.move, 'photoStudio.toolMove', Icons.open_with),
                                (StudioCanvasMode.resize, 'photoStudio.toolResize', Icons.photo_size_select_large),
                              ])
                                ChoiceChip(
                                  avatar: Icon(entry.$3, size: 16),
                                  label: Text(t(entry.$2)),
                                  selected: _canvasMode == entry.$1,
                                  onSelected: _decoding
                                      ? null
                                      : (_) => _setCanvasMode(entry.$1),
                                ),
                            ],
                          ),
                          if (_studio.selectedFrame != null ||
                              _studio.selectedEmojiStampId != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _studio.selectedFrame == null
                                      ? null
                                      : _deleteSelectedFrame,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(t('photoStudio.toolDelete')),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _studio.selectedFrame == null
                                      ? null
                                      : () {
                                          // Stroke color chips below remain the editor;
                                          // this control highlights the stroke section.
                                        },
                                  icon: const Icon(Icons.border_color_outlined),
                                  label: Text(t('photoStudio.toolStroke')),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            t('photoStudio.frameShape'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(t('photoStudio.shape.none')),
                                selected: _studio.draftShape == null,
                                onSelected: (_) => _setDraftShape(null),
                              ),
                              for (final shape in StudioFrameShape.values)
                                ChoiceChip(
                                  label: Text(
                                    t('photoStudio.shape.${shape.name}'),
                                  ),
                                  selected: _studio.draftShape == shape,
                                  onSelected: (_) => _setDraftShape(shape),
                                ),
                            ],
                          ),
                          if (_studio.frames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              t('photoStudio.frames'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < _studio.frames.length; i++)
                                  ChoiceChip(
                                    label: Text(
                                      _frameChipLabel(_studio.frames[i], i),
                                    ),
                                    selected: _studio.selectedStudioFrameId ==
                                        _studio.frames[i].studioFrameId,
                                    onSelected: (_) {
                                      _onSelectedStudioFrameIdChanged(
                                        _studio.frames[i].studioFrameId,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
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
                                  onTap: () => _applyStrokeColor(argb),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(argb),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _studio.draftStrokeArgb == argb
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                        width: _studio.draftStrokeArgb == argb
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
                          TextField(
                            controller: _stampController,
                            contentInsertionConfiguration:
                                ContentInsertionConfiguration(
                              onContentInserted: _handleInsertedContent,
                              allowedMimeTypes: const [
                                'image/png',
                                'image/jpeg',
                                'image/webp',
                              ],
                            ),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: t('photoStudio.customStamp'),
                              hintText: t('photoStudio.customStampHint'),
                            ),
                            onSubmitted: (_) => _armCustomStamp(),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.tonalIcon(
                              onPressed: _armCustomStamp,
                              icon: const Icon(Icons.gesture),
                              label: Text(t('photoStudio.armStamp')),
                            ),
                          ),
                          if (_pendingEmoji != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              t(
                                'photoStudio.stampArmed',
                                arguments: {'stamp': _pendingEmoji!},
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            t('photoStudio.stampShortcuts'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final emoji in _emojiShortcuts)
                                ActionChip(
                                  label: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  onPressed: () => _togglePendingStamp(emoji),
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
                              FilledButton.icon(
                                onPressed: _decoding ? null : _pickImage,
                                icon: const Icon(Icons.image_outlined),
                                label: Text(
                                  _decoding
                                      ? t('photoStudio.processing')
                                      : _studio.imageBytes == null
                                          ? t('photoStudio.importImage')
                                          : t('photoStudio.pickImage'),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _decoding ? null : _pasteImage,
                                icon: const Icon(Icons.content_paste),
                                label: Text(t('photoStudio.pasteImage')),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _studio.imageBytes == null
                                    ? null
                                    : _copyImage,
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
                                onPressed: selected == null
                                    ? null
                                    : _resetSelectedFrame,
                                icon: const Icon(Icons.crop_square_outlined),
                                label: Text(t('photoStudio.resetRect')),
                              ),
                              OutlinedButton.icon(
                                onPressed: selected == null
                                    ? null
                                    : _deleteSelectedFrame,
                                icon: const Icon(Icons.delete_outline),
                                label: Text(t('photoStudio.deleteFrame')),
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
                            value: rectText,
                            copyTooltip: t('common.copy'),
                            onCopy: selected == null
                                ? null
                                : () => _copy(selected.rect.csvText),
                          ),
                          const SizedBox(height: 8),
                          _CopyCard(
                            title: t('photoStudio.geometryLabel'),
                            value: geometry,
                            copyTooltip: t('common.copy'),
                            onCopy: selected == null
                                ? null
                                : () => _copy(geometry),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ToolDoorSelector(currentRouteName: RouteNames.photoStudio),
                  ],
                ),
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
  final VoidCallback? onCopy;

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
