import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/studio_frame.dart';
import '../domain/studio_frame_style.dart';

int _nextStudioObjectId = 0;

/// Monotonic frame/stamp ids (safe under dart2js ms-precision clocks).
String newStudioObjectId(String prefix) => '$prefix-${_nextStudioObjectId++}';

/// Local image canvas with zero-or-more normalized frames.
///
/// Frame / stamp state is owned by the parent. When [draftShape] is non-null,
/// dragging empty space creates a new frame (snipping-tool style). When null,
/// empty drags do not create; existing frames can still be selected/moved.
class PhotoRectCanvas extends StatefulWidget {
  const PhotoRectCanvas({
    super.key,
    required this.frames,
    required this.onFramesChanged,
    this.selectedStudioFrameId,
    this.onSelectedStudioFrameIdChanged,
    this.draftShape,
    this.draftStrokeArgb = StudioFrameColors.purple,
    this.imageBytes,
    this.height = 280,
    this.stamps = const <EmojiStamp>[],
    this.onStampsChanged,
    this.selectedEmojiStampId,
    this.onSelectedEmojiStampIdChanged,
    this.pendingEmoji,
    this.onEditStart,
    this.onEditEnd,
    this.onCanvasSizeChanged,
  });

  final List<StudioFrame> frames;
  final ValueChanged<List<StudioFrame>> onFramesChanged;
  final String? selectedStudioFrameId;
  final ValueChanged<String?>? onSelectedStudioFrameIdChanged;

  /// Active create tool; `null` = none (select/move only).
  final StudioFrameShape? draftShape;
  final int draftStrokeArgb;

  final Uint8List? imageBytes;
  final double height;
  final List<EmojiStamp> stamps;
  final ValueChanged<List<EmojiStamp>>? onStampsChanged;
  final String? selectedEmojiStampId;
  final ValueChanged<String?>? onSelectedEmojiStampIdChanged;

  /// When set, the next canvas tap places this emoji as a stamp.
  final String? pendingEmoji;

  /// Fired once at the start of a user gesture that mutates frame/stamps
  /// (create/move/resize frame, place/drag stamp). Not on every pan update.
  final VoidCallback? onEditStart;

  /// Fired when a mutating gesture ends (pan end/cancel or tap-place).
  final VoidCallback? onEditEnd;

  /// Reports the laid-out canvas size so export can match on-screen aspect.
  final ValueChanged<Size>? onCanvasSizeChanged;

  @override
  State<PhotoRectCanvas> createState() => _PhotoRectCanvasState();
}

class _PhotoRectCanvasState extends State<PhotoRectCanvas> {
  NormalizedRectHandle? _activeHandle;
  Offset? _lastLocal;
  Offset? _createOrigin;
  String? _creatingStudioFrameId;
  StudioFrame? _liveCreateFrame;
  String? _draggingEmojiStampId;
  /// Frame targeted by the active move/resize gesture (may lead parent selection).
  String? _editingStudioFrameId;
  bool _editStartNotified = false;
  Size? _lastReportedSize;

  static const double _handleHitSlop = 18;

  void _notifyEditStart() {
    if (_editStartNotified) return;
    _editStartNotified = true;
    widget.onEditStart?.call();
  }

  void _selectFrame(String? studioFrameId) {
    widget.onSelectedStudioFrameIdChanged?.call(studioFrameId);
  }

  double _stampHitRadius(Size size, EmojiStamp stamp) {
    final base = math.min(size.width, size.height) * 0.05 * stamp.scale;
    return math.max(18.0, base);
  }

  EmojiStamp? _hitStamp(Offset local, Size size) {
    for (final stamp in widget.stamps.reversed) {
      final center = Offset(stamp.x * size.width, stamp.y * size.height);
      if ((center - local).distance <= _stampHitRadius(size, stamp)) {
        return stamp;
      }
    }
    return null;
  }

  StudioFrame? _frameById(String? id) {
    if (id == null) return null;
    for (final frame in widget.frames) {
      if (frame.studioFrameId == id) return frame;
    }
    return null;
  }

  /// Topmost frame under [local], or null.
  StudioFrame? _hitFrameBody(Offset local, Size size) {
    for (final frame in widget.frames.reversed) {
      final rect = frame.rect.toPixelRect(size);
      if (rect.inflate(4).contains(local)) return frame;
    }
    return null;
  }

  NormalizedRectHandle? _hitTestHandles(
    Offset local,
    Size size,
    NormalizedRect rect,
  ) {
    final pixel = rect.toPixelRect(size);
    final corners = <NormalizedRectHandle, Offset>{
      NormalizedRectHandle.topLeft: pixel.topLeft,
      NormalizedRectHandle.topRight: pixel.topRight,
      NormalizedRectHandle.bottomLeft: pixel.bottomLeft,
      NormalizedRectHandle.bottomRight: pixel.bottomRight,
    };
    for (final entry in corners.entries) {
      if ((entry.value - local).distance <= _handleHitSlop) {
        return entry.key;
      }
    }

    final edges = <NormalizedRectHandle, Rect>{
      NormalizedRectHandle.left: Rect.fromLTWH(
        pixel.left - _handleHitSlop / 2,
        pixel.top + _handleHitSlop,
        _handleHitSlop,
        math.max(0.0, pixel.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.right: Rect.fromLTWH(
        pixel.right - _handleHitSlop / 2,
        pixel.top + _handleHitSlop,
        _handleHitSlop,
        math.max(0.0, pixel.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.top: Rect.fromLTWH(
        pixel.left + _handleHitSlop,
        pixel.top - _handleHitSlop / 2,
        math.max(0.0, pixel.width - _handleHitSlop * 2),
        _handleHitSlop,
      ),
      NormalizedRectHandle.bottom: Rect.fromLTWH(
        pixel.left + _handleHitSlop,
        pixel.bottom - _handleHitSlop / 2,
        math.max(0.0, pixel.width - _handleHitSlop * 2),
        _handleHitSlop,
      ),
    };
    for (final entry in edges.entries) {
      if (entry.value.contains(local)) return entry.key;
    }

    if (pixel.inflate(-4).contains(local)) {
      return NormalizedRectHandle.move;
    }
    return null;
  }

  void _selectEmojiStamp(String? emojiStampId) {
    widget.onSelectedEmojiStampIdChanged?.call(emojiStampId);
  }

  void _placePendingEmoji(Offset local, Size size) {
    final pending = widget.pendingEmoji;
    if (pending == null || pending.isEmpty) return;
    if (_placedEmojiForPointer) return;

    _notifyEditStart();
    _placedEmojiForPointer = true;
    final nx = (local.dx / size.width).clamp(0.0, 1.0);
    final ny = (local.dy / size.height).clamp(0.0, 1.0);
    final emojiStampId = newStudioObjectId('stamp');
    final next = <EmojiStamp>[
      ...widget.stamps,
      EmojiStamp(
        emojiStampId: emojiStampId,
        emoji: pending,
        x: nx,
        y: ny,
        scale: 1,
      ),
    ];
    widget.onStampsChanged?.call(next);
    _selectEmojiStamp(emojiStampId);
    _draggingEmojiStampId = emojiStampId;
  }

  Offset? _tapDownLocal;
  bool _placedEmojiForPointer = false;
  int? _activePointer;
  bool _pointerDragging = false;

  void _handleTapAt(Offset local, Size size) {
    final stamp = _hitStamp(local, size);
    if (stamp != null) {
      _selectEmojiStamp(stamp.emojiStampId);
      return;
    }
    if (widget.pendingEmoji != null &&
        widget.pendingEmoji!.isNotEmpty &&
        !_placedEmojiForPointer) {
      _placePendingEmoji(local, size);
      return;
    }
    final frame = _hitFrameBody(local, size);
    if (frame != null) {
      _selectFrame(frame.studioFrameId);
      return;
    }
    _selectFrame(null);
  }

  void _replaceFrame(StudioFrame updated) {
    widget.onFramesChanged([
      for (final frame in widget.frames)
        if (frame.studioFrameId == updated.studioFrameId) updated else frame,
    ]);
  }

  void _onPanStart(DragStartDetails details, Size size) {
    // Keep _tapDownLocal for pointer-move tracking; pointer-up uses
    // _pointerDragging to distinguish taps from drags.
    final stamp = _hitStamp(details.localPosition, size);
    if (stamp != null) {
      _notifyEditStart();
      _draggingEmojiStampId = stamp.emojiStampId;
      _activeHandle = null;
      _createOrigin = null;
      _creatingStudioFrameId = null;
      _liveCreateFrame = null;
      _selectEmojiStamp(stamp.emojiStampId);
      _lastLocal = details.localPosition;
      return;
    }

    final pending = widget.pendingEmoji;
    if (pending != null && pending.isNotEmpty) {
      if (!_placedEmojiForPointer) {
        _placePendingEmoji(details.localPosition, size);
      }
      _activeHandle = null;
      _createOrigin = null;
      _creatingStudioFrameId = null;
      _liveCreateFrame = null;
      _lastLocal = details.localPosition;
      return;
    }

    // Prefer topmost frame body over a buried selected-frame handle.
    final hitFrame = _hitFrameBody(details.localPosition, size);
    if (hitFrame != null) {
      _notifyEditStart();
      _selectFrame(hitFrame.studioFrameId);
      final handle =
          _hitTestHandles(details.localPosition, size, hitFrame.rect) ??
              NormalizedRectHandle.move;
      _createOrigin = null;
      _creatingStudioFrameId = null;
      _liveCreateFrame = null;
      _editingStudioFrameId = hitFrame.studioFrameId;
      _activeHandle = handle;
      _lastLocal = details.localPosition;
      return;
    }

    // Handle hit outside any frame body (slop past edges) — selected only.
    final selected = _frameById(widget.selectedStudioFrameId);
    if (selected != null) {
      final handle = _hitTestHandles(details.localPosition, size, selected.rect);
      if (handle != null) {
        _notifyEditStart();
        _createOrigin = null;
        _creatingStudioFrameId = null;
        _liveCreateFrame = null;
        _editingStudioFrameId = selected.studioFrameId;
        _activeHandle = handle;
        _lastLocal = details.localPosition;
        return;
      }
    }

    final draftShape = widget.draftShape;
    if (draftShape != null) {
      _notifyEditStart();
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      _createOrigin = Offset(nx, ny);
      _activeHandle = null;
      final studioFrameId = newStudioObjectId('frame');
      _creatingStudioFrameId = studioFrameId;
      final created = StudioFrame(
        studioFrameId: studioFrameId,
        rect: NormalizedRect.fromDiagonal(
          x0: nx,
          y0: ny,
          x1: nx,
          y1: ny,
        ),
        shape: draftShape,
        strokeArgb: widget.draftStrokeArgb,
      );
      _liveCreateFrame = created;
      widget.onFramesChanged([...widget.frames, created]);
      _selectFrame(studioFrameId);
      _lastLocal = details.localPosition;
      return;
    }

    _selectFrame(null);
    _activeHandle = null;
    _createOrigin = null;
    _creatingStudioFrameId = null;
    _liveCreateFrame = null;
    _lastLocal = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final draggingEmojiStampId = _draggingEmojiStampId;
    if (draggingEmojiStampId != null) {
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      widget.onStampsChanged?.call([
        for (final stamp in widget.stamps)
          if (stamp.emojiStampId == draggingEmojiStampId)
            stamp.copyWith(x: nx, y: ny)
          else
            stamp,
      ]);
      return;
    }

    final origin = _createOrigin;
    final creatingId = _creatingStudioFrameId;
    if (origin != null && creatingId != null) {
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      final live = (_liveCreateFrame ??
              StudioFrame(
                studioFrameId: creatingId,
                rect: NormalizedRect.initial,
                shape: widget.draftShape ?? StudioFrameShape.rectangle,
                strokeArgb: widget.draftStrokeArgb,
              ))
          .copyWith(
        rect: NormalizedRect.fromDiagonal(
          x0: origin.dx,
          y0: origin.dy,
          x1: nx,
          y1: ny,
        ),
      );
      _liveCreateFrame = live;
      // Parent setState from onPanStart may not have rebuilt yet when this runs
      // in the same pointer-move, so always append/replace by id.
      widget.onFramesChanged([
        for (final frame in widget.frames)
          if (frame.studioFrameId != creatingId) frame,
        live,
      ]);
      return;
    }

    final handle = _activeHandle;
    final last = _lastLocal;
    // Prefer gesture-local id so pan updates work before parent rebuilds
    // after a topmost-frame selection change in onPanStart.
    final editing = _frameById(_editingStudioFrameId) ??
        _frameById(widget.selectedStudioFrameId);
    if (handle == null || last == null || editing == null) return;
    final dx = (details.localPosition.dx - last.dx) / size.width;
    final dy = (details.localPosition.dy - last.dy) / size.height;
    _lastLocal = details.localPosition;
    _replaceFrame(
      editing.copyWith(
        rect: editing.rect.resized(handle: handle, dx: dx, dy: dy),
      ),
    );
  }

  void _finishGesture() {
    final creatingId = _creatingStudioFrameId;
    final live = _liveCreateFrame;
    if (creatingId != null && live != null) {
      final sanitized = live.copyWith(rect: live.rect.sanitized());
      widget.onFramesChanged([
        for (final frame in widget.frames)
          if (frame.studioFrameId != creatingId) frame,
        sanitized,
      ]);
    }
    final hadEdit = _editStartNotified;
    _createOrigin = null;
    _creatingStudioFrameId = null;
    _liveCreateFrame = null;
    _editingStudioFrameId = null;
    _activeHandle = null;
    _draggingEmojiStampId = null;
    _lastLocal = null;
    _editStartNotified = false;
    _placedEmojiForPointer = false;
    if (hadEdit) {
      widget.onEditEnd?.call();
    }
  }

  void _reportSizeIfNeeded(Size size) {
    if (_lastReportedSize == size) return;
    _lastReportedSize = size;
    final notify = widget.onCanvasSizeChanged;
    if (notify == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      notify(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, widget.height);
          _reportSizeIfNeeded(size);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _tapDownLocal = event.localPosition;
              _placedEmojiForPointer = false;
              _activePointer = event.pointer;
              _pointerDragging = false;
            },
            onPointerMove: (event) {
              if (_activePointer != event.pointer) return;
              if (!_pointerDragging) {
                final down = _tapDownLocal;
                if (down == null) return;
                final delta = event.localPosition - down;
                // Match a light pan slop so taps still place stamps.
                if (delta.distance < 4) return;
                _pointerDragging = true;
                _onPanStart(
                  DragStartDetails(
                    globalPosition: event.position,
                    localPosition: down,
                  ),
                  size,
                );
              }
              _onPanUpdate(
                DragUpdateDetails(
                  globalPosition: event.position,
                  localPosition: event.localPosition,
                  delta: event.delta,
                ),
                size,
              );
            },
            onPointerUp: (event) {
              if (_activePointer != null && event.pointer != _activePointer) {
                return;
              }
              final local = _tapDownLocal;
              final wasDragging = _pointerDragging;
              _activePointer = null;
              _pointerDragging = false;
              // If a pan claimed this pointer, finish the drag. A true tap still
              // has the down position and was not dragged.
              if (wasDragging) {
                _finishGesture();
              } else if (local != null && !_placedEmojiForPointer) {
                _handleTapAt(local, size);
                if (_editStartNotified || _draggingEmojiStampId != null) {
                  _finishGesture();
                }
              }
              _tapDownLocal = null;
            },
            onPointerCancel: (event) {
              if (_activePointer != null && event.pointer != _activePointer) {
                return;
              }
              _tapDownLocal = null;
              _activePointer = null;
              if (_pointerDragging ||
                  _editStartNotified ||
                  _draggingEmojiStampId != null) {
                _pointerDragging = false;
                _finishGesture();
              } else {
                _placedEmojiForPointer = false;
                _pointerDragging = false;
              }
            },
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: scheme.surfaceContainerHighest),
                    if (widget.imageBytes != null)
                      Image.memory(
                        widget.imageBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                      )
                    else
                      CustomPaint(
                        painter: _CheckerPainter(scheme.outlineVariant),
                      ),
                    CustomPaint(
                      painter: _FrameCanvasPainter(
                        frames: widget.frames,
                        selectedStudioFrameId: widget.selectedStudioFrameId,
                        dim: scheme.scrim.withValues(alpha: 0.28),
                        stamps: widget.stamps,
                        selectedEmojiStampId: widget.selectedEmojiStampId,
                        selectionAccent: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

class _FrameCanvasPainter extends CustomPainter {
  _FrameCanvasPainter({
    required this.frames,
    required this.selectedStudioFrameId,
    required this.dim,
    required this.stamps,
    required this.selectedEmojiStampId,
    required this.selectionAccent,
  });

  final List<StudioFrame> frames;
  final String? selectedStudioFrameId;
  final Color dim;
  final List<EmojiStamp> stamps;
  final String? selectedEmojiStampId;
  final Color selectionAccent;

  @override
  void paint(Canvas canvas, Size size) {
    StudioFrame? selected;
    for (final frame in frames) {
      if (frame.studioFrameId == selectedStudioFrameId) {
        selected = frame;
        break;
      }
    }

    if (selected != null) {
      final pixel = selected.rect.toPixelRect(size);
      final outside = Path()
        ..addRect(Offset.zero & size)
        ..addRect(pixel)
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(outside, Paint()..color = dim);
    }

    for (final frame in frames) {
      final pixel = frame.rect.toPixelRect(size);
      final accent = Color(frame.strokeArgb);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = frame.studioFrameId == selectedStudioFrameId ? 2.5 : 2
        ..color = accent;

      switch (frame.shape) {
        case StudioFrameShape.rectangle:
          canvas.drawRect(pixel, border);
        case StudioFrameShape.circle:
          canvas.drawCircle(
            pixel.center,
            math.min(pixel.width, pixel.height) / 2,
            border,
          );
        case StudioFrameShape.triangle:
          final path = Path()
            ..moveTo(pixel.center.dx, pixel.top)
            ..lineTo(pixel.right, pixel.bottom)
            ..lineTo(pixel.left, pixel.bottom)
            ..close();
          canvas.drawPath(path, border);
      }

      if (frame.studioFrameId == selectedStudioFrameId) {
        final handlePaint = Paint()..color = accent;
        final handleOutline = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white;
        for (final point in <Offset>[
          pixel.topLeft,
          pixel.topRight,
          pixel.bottomLeft,
          pixel.bottomRight,
          Offset(pixel.center.dx, pixel.top),
          Offset(pixel.center.dx, pixel.bottom),
          Offset(pixel.left, pixel.center.dy),
          Offset(pixel.right, pixel.center.dy),
        ]) {
          canvas.drawCircle(point, 5, handlePaint);
          canvas.drawCircle(point, 5, handleOutline);
        }
      }
    }

    for (final stamp in stamps) {
      final fontSize =
          math.min(size.width, size.height) * 0.1 * stamp.scale.clamp(0.4, 3.0);
      final tp = TextPainter(
        text: TextSpan(text: stamp.emoji, style: TextStyle(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      final origin = Offset(
        stamp.x * size.width - tp.width / 2,
        stamp.y * size.height - tp.height / 2,
      );
      tp.paint(canvas, origin);
      if (stamp.emojiStampId == selectedEmojiStampId) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              origin.dx - 4,
              origin.dy - 4,
              tp.width + 8,
              tp.height + 8,
            ),
            const Radius.circular(8),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = selectionAccent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrameCanvasPainter oldDelegate) =>
      oldDelegate.frames != frames ||
      oldDelegate.selectedStudioFrameId != selectedStudioFrameId ||
      oldDelegate.dim != dim ||
      oldDelegate.stamps != stamps ||
      oldDelegate.selectedEmojiStampId != selectedEmojiStampId ||
      oldDelegate.selectionAccent != selectionAccent;
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final col = (x / cell).floor();
        final row = (y / cell).floor();
        if ((col + row).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Validates image bytes by decoding a frame; returns null when invalid.
Future<Uint8List?> decodeRasterImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
    return bytes;
  } catch (_) {
    return null;
  }
}
