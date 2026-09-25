import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/clipboard/base64_image_bridge.dart';
import '../../../shared/display/display_catalog.dart';
import '../../../shared/display/display_scope.dart';
import '../data/clipboard_image_read.dart';
import '../data/native_image_normalize_adapter.dart';
import '../data/photo_import_limits.dart';
import '../data/photo_media_ports.dart';
import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/photo_import_status.dart';
import '../domain/photo_studio_history.dart';
import '../domain/photo_studio_state.dart';
import '../domain/studio_document.dart';
import '../domain/studio_export_result.dart';
import '../domain/studio_frame.dart';
import '../domain/studio_frame_style.dart';
import '../domain/studio_geometry.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/widgets/tool_door_selector.dart';
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
    this.imagePickOutcomeProvider,
    this.imageSaver,
    this.clipboardImageReader,
    this.imageDecodeAdapter,
  });

  /// Optional override for tests / non-web hosts.
  final Future<Uint8List?> Function()? imageBytesPicker;

  /// Optional structured picker seam for contract tests / alternate hosts.
  /// Prefer this when MIME provenance or typed pick outcomes must be preserved.
  final Future<PhotoPickOutcome> Function()? imagePickOutcomeProvider;

  /// Optional override for save/download (tests inject a fake saver).
  final StudioImageSaver? imageSaver;

  /// Optional override for reading binary clipboard images (tests / web).
  /// Prefer returning a structured [ClipboardImageRead] for reason-preserving tests.
  final Future<ClipboardImageRead> Function()? clipboardImageReader;

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

  static const _maxImageBytes = PhotoImportLimits.maxInputBytes;
  static const _maxImageClipboardChars = _maxImageBytes;

  /// Fallback until the first canvas layout reports its size.
  static const _fallbackCanvasSize = Size(760, 280);

  PhotoStudioState _studio = PhotoStudioState.initial();
  final PhotoStudioHistory _history = PhotoStudioHistory();
  final TextEditingController _stampController = TextEditingController();
  String? _pendingEmoji;
  Size _canvasSize = _fallbackCanvasSize;
  String? _status;
  PhotoImportStatus _importStatus = const PhotoImportStatus.idle();
  /// Last successfully exported document; dirty iff document content differs.
  PhotoStudioState _exportBaseline = PhotoStudioState.initial();
  int _imageLoadGeneration = 0;
  /// Lets Back pop once after Discard before the dirty rebuild settles.
  bool _allowPopAfterDiscard = false;

  bool get _canUndo => _history.canUndo;
  bool get _canRedo => _history.canRedo;
  bool get _isDirty => !_studio.sameDocumentAs(_exportBaseline);
  bool get _decoding => _importStatus.isBusy;

  /// Bump the image-load generation so in-flight work cannot clobber state.
  void _invalidatePendingImageLoad({bool markSuperseded = true}) {
    final wasBusy = _importStatus.isBusy;
    _imageLoadGeneration++;
    if (markSuperseded && wasBusy) {
      _importStatus = PhotoImportStatus.superseded(source: _importStatus.source);
    }
  }

  void _discardUnsavedChanges() {
    _invalidatePendingImageLoad();
    _history.clear();
    _studio = _exportBaseline;
    _pendingEmoji = null;
  }

  @override
  void dispose() {
    // Drop any in-flight decode continuation when leaving the route.
    _invalidatePendingImageLoad();
    _stampController.dispose();
    super.dispose();
  }

  void _beginUndoGesture() {
    _history.beginGesture(_studio);
  }

  void _endUndoGesture() {
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
    final snap = _history.undo(_studio);
    if (snap == null) return;
    setState(() {
      _invalidatePendingImageLoad();
      _studio = snap;
      _status = DisplayScope.of(context).text('photoStudio.undoDone');
    });
  }

  void _redoOnce() {
    final snap = _history.redo(_studio);
    if (snap == null) return;
    setState(() {
      _invalidatePendingImageLoad();
      _studio = snap;
      _status = DisplayScope.of(context).text('photoStudio.redoDone');
    });
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_isDirty) return true;
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

  int _beginImportOperation(PhotoImportSource source) {
    final generation = ++_imageLoadGeneration;
    _importStatus = PhotoImportStatus.loading(source: source);
    return generation;
  }

  bool _isCurrentImport(int generation) =>
      mounted && generation == _imageLoadGeneration;

  void _setImportStatusIfCurrent(int generation, PhotoImportStatus status) {
    if (!_isCurrentImport(generation)) return;
    setState(() => _importStatus = status);
  }

  Future<void> _importImageBytes(
    Uint8List rawBytes, {
    required PhotoImportSource source,
    required int generation,
    String? declaredMimeType,
  }) async {
    // All ingress adapters converge here. When an acquisition boundary reports
    // a non-empty MIME type, reject a non-image declaration before decoding.
    // Image MIME remains provenance only: byte/decode validation is authoritative.
    if (declaredMimeType != null &&
        declaredMimeType.isNotEmpty &&
        !declaredMimeType.startsWith('image/')) {
      _setImportStatusIfCurrent(
        generation,
        PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.unsupportedFormat,
          source: source,
        ),
      );
      return;
    }
    final rawReject = PhotoImportGate.rejectRawBytes(rawBytes);
    if (rawReject != null) {
      _setImportStatusIfCurrent(
        generation,
        PhotoImportStatus.failure(
          reason: PhotoImportStatus.fromRejection(rawReject),
          source: source,
        ),
      );
      return;
    }
    if (!_isCurrentImport(generation)) return;
    try {
      // Web keeps the original bytes, but success still requires a real frame
      // decode. This proves the browser/Flutter codec can materialize the image
      // without reintroducing canvas normalization or PNG re-encoding.
      if (kIsWeb && widget.imageDecodeAdapter == null) {
        final decoded = await decodeImageFrameSize(rawBytes);
        if (!_isCurrentImport(generation)) return;
        if (decoded == null) {
          _setImportStatusIfCurrent(
            generation,
            PhotoImportStatus.failure(
              reason: PhotoImportFailureReason.unsupportedFormat,
              source: source,
            ),
          );
          return;
        }
        final sizeReject = PhotoImportGate.rejectDecodedSize(
          width: decoded.width,
          height: decoded.height,
        );
        if (sizeReject != null) {
          _setImportStatusIfCurrent(
            generation,
            PhotoImportStatus.failure(
              reason: PhotoImportStatus.fromRejection(sizeReject),
              source: source,
            ),
          );
          return;
        }
        setState(() {
          _mutateWithUndo((s) => s.copyWith(imageBytes: rawBytes));
          _importStatus = PhotoImportStatus.success(
            source: source,
            formatLabel: declaredMimeType?.split('/').last.toUpperCase() ?? 'IMAGE',
            width: decoded.width,
            height: decoded.height,
          );
        });
        return;
      }

      PhotoImportRejection? decodeReject;
      final adapter = widget.imageDecodeAdapter ?? nativeImageNormalizeAdapter;
      final validated = await loadStudioImageBytes(
        rawBytes,
        nativeDecodeAdapter: adapter,
        onRejected: (rejection) => decodeReject = rejection,
      );
      if (!_isCurrentImport(generation)) return;
      if (validated == null) {
        _setImportStatusIfCurrent(
          generation,
          PhotoImportStatus.failure(
            reason: PhotoImportStatus.fromRejection(
              decodeReject ?? PhotoImportRejection.undecodable,
            ),
            source: source,
          ),
        );
        return;
      }
      final compact = await Base64ImageBridge.downscaleToPng(
        validated,
        scale: PhotoImportLimits.defaultDownscale,
        maxLongEdge: PhotoImportLimits.maxDocumentLongEdge,
      );
      if (!_isCurrentImport(generation)) return;
      if (compact.bytes.isEmpty) {
        _setImportStatusIfCurrent(
          generation,
          PhotoImportStatus.failure(
            reason: PhotoImportFailureReason.decodeFailed,
            source: source,
          ),
        );
        return;
      }
      final size = _pngIhDrSize(compact.bytes);
      if (!_isCurrentImport(generation)) return;
      setState(() {
        _mutateWithUndo((s) => s.copyWith(imageBytes: compact.bytes));
        _importStatus = PhotoImportStatus.success(
          source: source,
          formatLabel: 'PNG',
          width: size.$1,
          height: size.$2,
        );
      });
    } catch (_) {
      _setImportStatusIfCurrent(
        generation,
        PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.decodeFailed,
          source: source,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    late final int generation;
    setState(() {
      generation = _beginImportOperation(PhotoImportSource.pick);
    });
    try {
      if (widget.imageBytesPicker != null) {
        final bytes = await widget.imageBytesPicker!();
        if (!_isCurrentImport(generation)) return;
        if (bytes == null || bytes.isEmpty) {
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.cancelled(source: PhotoImportSource.pick),
          );
          return;
        }
        await _importImageBytes(
          bytes,
          source: PhotoImportSource.pick,
          generation: generation,
        );
        return;
      }

      final outcome = await (widget.imagePickOutcomeProvider != null
          ? widget.imagePickOutcomeProvider!()
          : pickLocalImageBytesDetailed());
      if (!_isCurrentImport(generation)) return;
      switch (outcome.status) {
        case PhotoPickStatus.cancelled:
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.cancelled(source: PhotoImportSource.pick),
          );
          return;
        case PhotoPickStatus.unavailable:
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.failure(
              reason: PhotoImportFailureReason.pickUnavailable,
              source: PhotoImportSource.pick,
            ),
          );
          return;
        case PhotoPickStatus.failed:
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.failure(
              reason: PhotoImportFailureReason.pickFailed,
              source: PhotoImportSource.pick,
            ),
          );
          return;
        case PhotoPickStatus.rejected:
          _setImportStatusIfCurrent(
            generation,
            PhotoImportStatus.failure(
              reason: PhotoImportStatus.fromRejection(
                outcome.rejection ?? PhotoImportRejection.undecodable,
              ),
              source: PhotoImportSource.pick,
            ),
          );
          return;
        case PhotoPickStatus.success:
          final bytes = outcome.bytes;
          if (bytes == null || bytes.isEmpty) {
            _setImportStatusIfCurrent(
              generation,
              const PhotoImportStatus.failure(
                reason: PhotoImportFailureReason.decodeFailed,
                source: PhotoImportSource.pick,
              ),
            );
            return;
          }
          await _importImageBytes(
            bytes,
            source: PhotoImportSource.pick,
            generation: generation,
            declaredMimeType: outcome.declaredMimeType,
          );
      }
    } catch (_) {
      _setImportStatusIfCurrent(
        generation,
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.pickFailed,
          source: PhotoImportSource.pick,
        ),
      );
    }
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
    late final int generation;
    setState(() {
      generation = _beginImportOperation(PhotoImportSource.paste);
    });
    try {
      var text = '';
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (!_isCurrentImport(generation)) return;
        text = data?.text?.trim() ?? '';
      } catch (_) {
        if (!_isCurrentImport(generation)) return;
      }

      if (text.isNotEmpty) {
        final imageCandidate =
            text.startsWith('data:image/') || _looksLikeRawBase64(text);
        if (imageCandidate && text.length <= _maxImageClipboardChars) {
          try {
            final payload = Base64ImageBridge.decodeText(text);
            await _importImageBytes(
              payload.bytes,
              source: PhotoImportSource.paste,
              generation: generation,
            );
            return;
          } catch (_) {
            // Fall through to binary clipboard.
          }
        } else if (imageCandidate && text.length > _maxImageClipboardChars) {
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.failure(
              reason: PhotoImportFailureReason.tooLarge,
              source: PhotoImportSource.paste,
            ),
          );
          return;
        }
      }

      final customReader = widget.clipboardImageReader;
      final ClipboardImageRead read = customReader != null
          ? await customReader()
          : await readWebClipboardImage(maxBytes: _maxImageBytes);
      if (!_isCurrentImport(generation)) return;
      switch (read.kind) {
        case ClipboardImageReadKind.bytes:
          final bytes = read.bytes;
          if (bytes != null && bytes.isNotEmpty) {
            await _importImageBytes(
              bytes,
              source: PhotoImportSource.paste,
              generation: generation,
            );
            return;
          }
          _setImportStatusIfCurrent(
            generation,
            const PhotoImportStatus.failure(
              reason: PhotoImportFailureReason.noClipboardImage,
              source: PhotoImportSource.paste,
            ),
          );
        case ClipboardImageReadKind.empty:
        case ClipboardImageReadKind.denied:
        case ClipboardImageReadKind.unavailable:
        case ClipboardImageReadKind.tooLarge:
        case ClipboardImageReadKind.readFailed:
          _setImportStatusIfCurrent(
            generation,
            PhotoImportStatus.failure(
              reason: PhotoImportStatus.fromClipboardRead(read.kind),
              source: PhotoImportSource.paste,
            ),
          );
      }
    } catch (_) {
      _setImportStatusIfCurrent(
        generation,
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.clipboardUnavailable,
          source: PhotoImportSource.paste,
        ),
      );
    }
  }

  void _handleInsertedContent(KeyboardInsertedContent content) {
    late final int generation;
    setState(() {
      generation = _beginImportOperation(PhotoImportSource.insert);
    });
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty) {
      _setImportStatusIfCurrent(
        generation,
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.decodeFailed,
          source: PhotoImportSource.insert,
        ),
      );
      return;
    }
    if (bytes.lengthInBytes > _maxImageBytes) {
      _setImportStatusIfCurrent(
        generation,
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.tooLarge,
          source: PhotoImportSource.insert,
        ),
      );
      return;
    }
    _importImageBytes(
      bytes,
      source: PhotoImportSource.insert,
      generation: generation,
      declaredMimeType: content.mimeType,
    );
  }

  Future<void> _retryImport() async {
    switch (_importStatus.source) {
      case PhotoImportSource.paste:
        await _pasteImage();
      case PhotoImportSource.pick:
      case PhotoImportSource.insert:
      case null:
        await _pickImage();
    }
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
      final wasBusy = _importStatus.isBusy;
      _invalidatePendingImageLoad();
      _mutateWithUndo((s) => s.copyWith(imageBytes: null));
      // Keep superseded when an in-flight decode was discarded; otherwise idle.
      if (!wasBusy) {
        _importStatus = const PhotoImportStatus.idle();
      }
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
    // Freeze the document being exported so later edits stay dirty.
    final exportedState = _studio;
    final result = await exportStudioPng(
      document: StudioDocument.fromState(
        exportedState,
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
        _exportBaseline = exportedState;
      }
    });
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
      _pendingEmoji = _pendingEmoji == text ? null : text;
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
    if (_studio.draftShape == shape) return;
    _setStateWithUndo((s) => s.copyWith(draftShape: shape));
  }

  void _onCanvasSizeChanged(Size size) {
    if (size == _canvasSize) return;
    setState(() => _canvasSize = size);
  }

  Widget _buildImportStatus(
    BuildContext context,
    String Function(String key, {Map<String, Object?> arguments}) t,
  ) {
    final status = _importStatus;
    final primary = t(status.messageKey);
    final metaKey = status.metaMessageKey;
    final meta = metaKey == null
        ? null
        : t(metaKey, arguments: status.metaArguments);
    final fileName = status.fileName;
    final scheme = Theme.of(context).colorScheme;
    final Color tone = switch (status.phase) {
      PhotoImportPhase.failure => scheme.error,
      PhotoImportPhase.success => scheme.primary,
      PhotoImportPhase.loading => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };

    final resultSignal = switch (status.phase) {
      PhotoImportPhase.success =>
        'photo-import-result success:${(status.formatLabel ?? 'image').toLowerCase()}:${status.width ?? 0}x${status.height ?? 0}',
      PhotoImportPhase.failure =>
        'photo-import-result rejected:${status.failureReason?.name ?? 'decodeFailed'}',
      _ => 'photo-import-result ${status.phase.name}',
    };

    return Semantics(
      liveRegion: true,
      label: resultSignal,
      child: Semantics(
        label: [
          primary,
          if (meta != null) meta,
          if (fileName != null && fileName.isNotEmpty) fileName,
        ].join(' '),
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: tone, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status.isBusy)
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          primary,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: tone),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    primary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tone,
                          fontWeight: status.phase == PhotoImportPhase.failure ||
                                  status.phase == PhotoImportPhase.success
                              ? FontWeight.w600
                              : null,
                        ),
                  ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (fileName != null && fileName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(fileName, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (status.canRetry) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _decoding ? null : _retryImport,
                    child: Text(t('photoStudio.importRetry')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
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
      canPop: !_isDirty || _allowPopAfterDiscard,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          _allowPopAfterDiscard = false;
          return;
        }
        final leave = await _confirmDiscardIfDirty();
        if (!mounted || !leave) return;
        // Restore in the same setState as the allow-pop flag so the next
        // build's canPop is true (for any subsequent maybePop / system back).
        setState(() {
          _discardUnsavedChanges();
          _allowPopAfterDiscard = true;
        });
        // Imperative pop does not consult canPop / popDisposition, so we can
        // leave immediately without waiting for the rebuild frame (which is
        // what re-enters the dialog when maybePop is used too early).
        Navigator.of(context).pop();
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
                if (_isDirty) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            actions: [
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
              PopupMenuButton<String>(
                tooltip: t('photoStudio.languageMenu'),
                icon: const Icon(Icons.language),
                onSelected: (locale) {
                  DisplayScope.of(context).setLocale(locale);
                },
                itemBuilder: (context) => [
                  for (final locale in DisplayCatalog.supportedLocales)
                    PopupMenuItem<String>(
                      value: locale,
                      child: Text(locale.toUpperCase()),
                    ),
                ],
              ),
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
                          if (_studio.imageBytes == null) ...[
                            Text(
                              t('photoStudio.emptyBody'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                          ],
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
                                draftShape: _studio.draftShape,
                                draftStrokeArgb: _studio.draftStrokeArgb,
                                imageBytes: _studio.imageBytes,
                                stamps: _studio.stamps,
                                onStampsChanged: _onStampsChanged,
                                selectedEmojiStampId:
                                    _studio.selectedEmojiStampId,
                                onSelectedEmojiStampIdChanged:
                                    _onSelectedEmojiStampIdChanged,
                                pendingEmoji: _pendingEmoji,
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
                                        Text(t('photoStudio.importLoading')),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildImportStatus(context, t),
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
                                  onPressed: () {
                                    setState(() {
                                      if (_pendingEmoji == emoji) {
                                        _pendingEmoji = null;
                                      } else {
                                        _pendingEmoji = emoji;
                                        _stampController.text = emoji;
                                      }
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
                                label: Text(
                                  _studio.imageBytes == null
                                      ? t('photoStudio.importImage')
                                      : t('photoStudio.replaceImage'),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _pasteImage,
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
                                onPressed: (!_decoding && _studio.imageBytes == null)
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
                              onPressed: _decoding ? null : _savePng,
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
                    ToolDoorSelector(
                      currentRouteName: RouteNames.photoStudio,
                      beforeNavigate: () async {
                        final ok = await _confirmDiscardIfDirty();
                        if (ok && mounted && _isDirty) {
                          setState(_discardUnsavedChanges);
                        }
                        return ok;
                      },
                    ),
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

(int, int) _pngIhDrSize(Uint8List bytes) {
  if (bytes.lengthInBytes < 24) return (0, 0);
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
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
