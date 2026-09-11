import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

/// Axis-aligned rectangle in normalized image/canvas space (0..1).
///
/// Independent of whether an image is loaded; callers keep one instance across
/// image attach / clear / replace.
class NormalizedRect {
  const NormalizedRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Default inset rectangle, usable before any image is present.
  static const NormalizedRect initial = NormalizedRect(
    left: 0.2,
    top: 0.2,
    right: 0.8,
    bottom: 0.8,
  );

  static const double minSize = 0.04;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  NormalizedRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) =>
      NormalizedRect(
        left: left ?? this.left,
        top: top ?? this.top,
        right: right ?? this.right,
        bottom: bottom ?? this.bottom,
      );

  /// Clamps to 0..1 and enforces min size / ordering.
  NormalizedRect sanitized() {
    var l = left.clamp(0.0, 1.0).toDouble();
    var t = top.clamp(0.0, 1.0).toDouble();
    var r = right.clamp(0.0, 1.0).toDouble();
    var b = bottom.clamp(0.0, 1.0).toDouble();
    if (r < l) {
      final swap = l;
      l = r;
      r = swap;
    }
    if (b < t) {
      final swap = t;
      t = b;
      b = swap;
    }
    if (r - l < minSize) {
      r = math.min(1.0, l + minSize);
      l = math.max(0.0, r - minSize);
    }
    if (b - t < minSize) {
      b = math.min(1.0, t + minSize);
      t = math.max(0.0, b - minSize);
    }
    return NormalizedRect(left: l, top: t, right: r, bottom: b);
  }

  Rect toPixelRect(Size size) => Rect.fromLTRB(
        left * size.width,
        top * size.height,
        right * size.width,
        bottom * size.height,
      );

  NormalizedRect translated(double dx, double dy) {
    var l = left + dx;
    var t = top + dy;
    var r = right + dx;
    var b = bottom + dy;
    if (l < 0) {
      r -= l;
      l = 0;
    }
    if (t < 0) {
      b -= t;
      t = 0;
    }
    if (r > 1) {
      l -= r - 1;
      r = 1;
    }
    if (b > 1) {
      t -= b - 1;
      b = 1;
    }
    return NormalizedRect(left: l, top: t, right: r, bottom: b).sanitized();
  }

  NormalizedRect resized({
    required NormalizedRectHandle handle,
    required double dx,
    required double dy,
  }) {
    var l = left;
    var t = top;
    var r = right;
    var b = bottom;
    switch (handle) {
      case NormalizedRectHandle.move:
        return translated(dx, dy);
      case NormalizedRectHandle.topLeft:
        l += dx;
        t += dy;
        break;
      case NormalizedRectHandle.topRight:
        r += dx;
        t += dy;
        break;
      case NormalizedRectHandle.bottomLeft:
        l += dx;
        b += dy;
        break;
      case NormalizedRectHandle.bottomRight:
        r += dx;
        b += dy;
        break;
      case NormalizedRectHandle.left:
        l += dx;
        break;
      case NormalizedRectHandle.right:
        r += dx;
        break;
      case NormalizedRectHandle.top:
        t += dy;
        break;
      case NormalizedRectHandle.bottom:
        b += dy;
        break;
    }
    return NormalizedRect(left: l, top: t, right: r, bottom: b).sanitized();
  }

  String get labeledText =>
      'left: ${left.toStringAsFixed(4)}\n'
      'top: ${top.toStringAsFixed(4)}\n'
      'right: ${right.toStringAsFixed(4)}\n'
      'bottom: ${bottom.toStringAsFixed(4)}';

  String get csvText =>
      '${left.toStringAsFixed(4)}, ${top.toStringAsFixed(4)}, '
      '${right.toStringAsFixed(4)}, ${bottom.toStringAsFixed(4)}';
}

enum NormalizedRectHandle {
  move,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  left,
  right,
  top,
  bottom,
}
