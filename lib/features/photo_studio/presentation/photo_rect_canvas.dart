import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/studio_frame_style.dart';

/// Local image canvas with a normalized frame that works with or without an
/// image. Rectangle / stamp state is owned by the parent.
class PhotoRectCanvas extends StatefulWidget {
  const PhotoRectCanvas({
    super.key,
    required this.rect,
    required this.onRectChanged,
    this.imageBytes,
    this.height = 280,
    this.shape = StudioFrameShape.rectangle,
    this.strokeColor,
    this.stamps = const <EmojiStamp>[],
    this.onStampsChanged,
    this.selectedEmojiStampId,
    this.onSelectedEmojiStampIdChanged,
    this.pendingEmoji,
    this.onEditStart,
    this.onEditEnd,
    this.onCanvasSizeChanged,
  });

  final NormalizedRect rect;
  final ValueChanged<NormalizedRect> onRectChanged;
  final Uint8List? imageBytes;
  final double height;
  final StudioFrameShape shape;
  final Color? strokeColor;
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
  NormalizedRect? _liveCreateRect;
  String? _draggingEmojiStampId;
  bool _editStartNotified = false;
  Size? _lastReportedSize;

  static const double _handleHitSlop = 18;

  void _notifyEditStart() {
    if (_editStartNotified) return;
    _editStartNotified = true;
    widget.onEditStart?.call();
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

  NormalizedRectHandle? _hitTest(Offset local, Size size) {
    final rect = widget.rect.toPixelRect(size);
    final corners = <NormalizedRectHandle, Offset>{
      NormalizedRectHandle.topLeft: rect.topLeft,
      NormalizedRectHandle.topRight: rect.topRight,
      NormalizedRectHandle.bottomLeft: rect.bottomLeft,
      NormalizedRectHandle.bottomRight: rect.bottomRight,
    };
    for (final entry in corners.entries) {
      if ((entry.value - local).distance <= _handleHitSlop) {
        return entry.key;
      }
    }

    final edges = <NormalizedRectHandle, Rect>{
      NormalizedRectHandle.left: Rect.fromLTWH(
        rect.left - _handleHitSlop / 2,
        rect.top + _handleHitSlop,
        _handleHitSlop,
        math.max(0.0, rect.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.right: Rect.fromLTWH(
        rect.right - _handleHitSlop / 2,
        rect.top + _handleHitSlop,
        _handleHitSlop,
        math.max(0.0, rect.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.top: Rect.fromLTWH(
        rect.left + _handleHitSlop,
        rect.top - _handleHitSlop / 2,
        math.max(0.0, rect.width - _handleHitSlop * 2),
        _handleHitSlop,
      ),
      NormalizedRectHandle.bottom: Rect.fromLTWH(
        rect.left + _handleHitSlop,
        rect.bottom - _handleHitSlop / 2,
        math.max(0.0, rect.width - _handleHitSlop * 2),
        _handleHitSlop,
      ),
    };
    for (final entry in edges.entries) {
      if (entry.value.contains(local)) return entry.key;
    }

    if (rect.inflate(-4).contains(local)) {
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
    final emojiStampId = 'stamp-${DateTime.now().microsecondsSinceEpoch}';
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
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _tapDownLocal = null;
    final stamp = _hitStamp(details.localPosition, size);
    if (stamp != null) {
      _notifyEditStart();
      _draggingEmojiStampId = stamp.emojiStampId;
      _activeHandle = null;
      _createOrigin = null;
      _liveCreateRect = null;
      _selectEmojiStamp(stamp.emojiStampId);
      _lastLocal = details.localPosition;
      return;
    }

    final pending = widget.pendingEmoji;
    if (pending != null && pending.isNotEmpty) {
      // Near-taps often lose the tap arena to pan. Place once here, then drag
      // the new stamp so we never double-place with a later onTap.
      if (!_placedEmojiForPointer) {
        _placePendingEmoji(details.localPosition, size);
      }
      // _placePendingEmoji sets _draggingEmojiStampId when it places.
      _activeHandle = null;
      _createOrigin = null;
      _liveCreateRect = null;
      _lastLocal = details.localPosition;
      return;
    }

    final hit = _hitTest(details.localPosition, size);
    if (hit == null) {
      _notifyEditStart();
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      _createOrigin = Offset(nx, ny);
      _activeHandle = null;
      final created = NormalizedRect.fromDiagonal(
        x0: nx,
        y0: ny,
        x1: nx,
        y1: ny,
      );
      _liveCreateRect = created;
      widget.onRectChanged(created);
    } else {
      _notifyEditStart();
      _createOrigin = null;
      _liveCreateRect = null;
      _activeHandle = hit;
    }
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
    if (origin != null) {
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      final created = NormalizedRect.fromDiagonal(
        x0: origin.dx,
        y0: origin.dy,
        x1: nx,
        y1: ny,
      );
      _liveCreateRect = created;
      widget.onRectChanged(created);
      return;
    }

    final handle = _activeHandle;
    final last = _lastLocal;
    if (handle == null || last == null) return;
    final dx = (details.localPosition.dx - last.dx) / size.width;
    final dy = (details.localPosition.dy - last.dy) / size.height;
    _lastLocal = details.localPosition;
    widget.onRectChanged(widget.rect.resized(handle: handle, dx: dx, dy: dy));
  }

  void _finishGesture() {
    final live = _liveCreateRect;
    if (_createOrigin != null && live != null) {
      widget.onRectChanged(live.sanitized());
    }
    final hadEdit = _editStartNotified;
    _createOrigin = null;
    _liveCreateRect = null;
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
    final accent = widget.strokeColor ?? scheme.primary;
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
            },
            onPointerUp: (_) {
              final local = _tapDownLocal;
              // If a pan claimed this pointer, _tapDownLocal was cleared in
              // onPanStart. A true tap still has the down position.
              if (local != null && !_placedEmojiForPointer) {
                _handleTapAt(local, size);
              }
              _tapDownLocal = null;
              // Pure taps never reach onPanEnd; close gesture temp state so the
              // next drag can take its own undo snapshot.
              if (_editStartNotified || _draggingEmojiStampId != null) {
                _finishGesture();
              }
            },
            onPointerCancel: (_) {
              _tapDownLocal = null;
              if (_editStartNotified || _draggingEmojiStampId != null) {
                _finishGesture();
              } else {
                _placedEmojiForPointer = false;
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _onPanStart(details, size),
              onPanUpdate: (details) => _onPanUpdate(details, size),
              onPanEnd: (_) => _finishGesture(),
              onPanCancel: _finishGesture,
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
                        rect: widget.rect,
                        shape: widget.shape,
                        accent: accent,
                        dim: scheme.scrim.withValues(alpha: 0.28),
                        stamps: widget.stamps,
                        selectedEmojiStampId: widget.selectedEmojiStampId,
                      ),
                    ),
                  ],
                ),
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
    required this.rect,
    required this.shape,
    required this.accent,
    required this.dim,
    required this.stamps,
    required this.selectedEmojiStampId,
  });

  final NormalizedRect rect;
  final StudioFrameShape shape;
  final Color accent;
  final Color dim;
  final List<EmojiStamp> stamps;
  final String? selectedEmojiStampId;

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = rect.toPixelRect(size);
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addRect(pixel)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = dim);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = accent;

    switch (shape) {
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
            ..color = accent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrameCanvasPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.shape != shape ||
      oldDelegate.accent != accent ||
      oldDelegate.dim != dim ||
      oldDelegate.stamps != stamps ||
      oldDelegate.selectedEmojiStampId != selectedEmojiStampId;
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
