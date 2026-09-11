import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/normalized_rect.dart';

/// Local image canvas with a normalized rectangle that works with or without
/// an image. Rectangle state is owned by the parent.
class ImageRectOverlay extends StatefulWidget {
  const ImageRectOverlay({
    super.key,
    required this.rect,
    required this.onRectChanged,
    this.imageBytes,
    this.height = 280,
  });

  final NormalizedRect rect;
  final ValueChanged<NormalizedRect> onRectChanged;
  final Uint8List? imageBytes;
  final double height;

  @override
  State<ImageRectOverlay> createState() => _ImageRectOverlayState();
}

class _ImageRectOverlayState extends State<ImageRectOverlay> {
  NormalizedRectHandle? _activeHandle;
  Offset? _lastLocal;
  /// Normalized origin for outside-drag create; null when resizing/moving.
  Offset? _createOrigin;

  static const double _handleHitSlop = 18;

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
        mathMax(0, rect.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.right: Rect.fromLTWH(
        rect.right - _handleHitSlop / 2,
        rect.top + _handleHitSlop,
        _handleHitSlop,
        mathMax(0, rect.height - _handleHitSlop * 2),
      ),
      NormalizedRectHandle.top: Rect.fromLTWH(
        rect.left + _handleHitSlop,
        rect.top - _handleHitSlop / 2,
        mathMax(0, rect.width - _handleHitSlop * 2),
        _handleHitSlop,
      ),
      NormalizedRectHandle.bottom: Rect.fromLTWH(
        rect.left + _handleHitSlop,
        rect.bottom - _handleHitSlop / 2,
        mathMax(0, rect.width - _handleHitSlop * 2),
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

  double mathMax(double a, double b) => a > b ? a : b;

  void _onPanStart(DragStartDetails details, Size size) {
    final hit = _hitTest(details.localPosition, size);
    if (hit == null) {
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      _createOrigin = Offset(nx, ny);
      _activeHandle = null;
      widget.onRectChanged(
        NormalizedRect.fromDiagonal(x0: nx, y0: ny, x1: nx, y1: ny),
      );
    } else {
      _createOrigin = null;
      _activeHandle = hit;
    }
    _lastLocal = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final origin = _createOrigin;
    if (origin != null) {
      final nx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
      final ny = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
      widget.onRectChanged(
        NormalizedRect.fromDiagonal(
          x0: origin.dx,
          y0: origin.dy,
          x1: nx,
          y1: ny,
        ),
      );
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

  void _onPanEnd(DragEndDetails details) {
    if (_createOrigin != null) {
      widget.onRectChanged(widget.rect.sanitized());
    }
    _createOrigin = null;
    _activeHandle = null;
    _lastLocal = null;
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
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => _onPanStart(details, size),
            onPanUpdate: (details) => _onPanUpdate(details, size),
            onPanEnd: _onPanEnd,
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
                    CustomPaint(painter: _CheckerPainter(scheme.outlineVariant)),
                  CustomPaint(
                    painter: _RectOverlayPainter(
                      rect: widget.rect,
                      accent: scheme.primary,
                      dim: scheme.scrim.withValues(alpha: 0.35),
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

class _RectOverlayPainter extends CustomPainter {
  _RectOverlayPainter({
    required this.rect,
    required this.accent,
    required this.dim,
  });

  final NormalizedRect rect;
  final Color accent;
  final Color dim;

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
      ..strokeWidth = 2
      ..color = accent;
    canvas.drawRect(pixel, border);

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

  @override
  bool shouldRepaint(covariant _RectOverlayPainter oldDelegate) =>
      oldDelegate.rect.left != rect.left ||
      oldDelegate.rect.top != rect.top ||
      oldDelegate.rect.right != rect.right ||
      oldDelegate.rect.bottom != rect.bottom ||
      oldDelegate.accent != accent ||
      oldDelegate.dim != dim;
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
