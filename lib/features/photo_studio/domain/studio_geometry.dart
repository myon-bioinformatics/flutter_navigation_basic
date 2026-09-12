import 'dart:math' as math;

import 'normalized_rect.dart';
import 'studio_frame_style.dart';

/// Geometry helpers for photo-studio frames.
///
/// Midpoints and triangle/circle derived points mirror the Python oracle under
/// `tool/python` so Dart UI and pytest stay aligned.
class StudioGeometry {
  const StudioGeometry._();

  static ({double x, double y}) midpoint({
    required double x0,
    required double y0,
    required double x1,
    required double y1,
  }) =>
      (x: (x0 + x1) / 2, y: (y0 + y1) / 2);

  /// Edge midpoints of an axis-aligned rectangle, clockwise from top.
  static List<({double x, double y})> rectangleEdgeMidpoints(
    NormalizedRect rect,
  ) {
    final c = midpoint;
    return [
      c(x0: rect.left, y0: rect.top, x1: rect.right, y1: rect.top),
      c(x0: rect.right, y0: rect.top, x1: rect.right, y1: rect.bottom),
      c(x0: rect.left, y0: rect.bottom, x1: rect.right, y1: rect.bottom),
      c(x0: rect.left, y0: rect.top, x1: rect.left, y1: rect.bottom),
    ];
  }

  /// Inscribed circle from a bounding box (center + radius in normalized units).
  static ({double cx, double cy, double radius}) circleFromBounds(
    NormalizedRect rect,
  ) {
    final cx = (rect.left + rect.right) / 2;
    final cy = (rect.top + rect.bottom) / 2;
    final radius = math.min(rect.width, rect.height) / 2;
    return (cx: cx, cy: cy, radius: radius);
  }

  /// Isosceles triangle: apex at top-center, base along the bottom edge.
  static List<({double x, double y})> triangleVertices(NormalizedRect rect) {
    final apexX = (rect.left + rect.right) / 2;
    return [
      (x: apexX, y: rect.top),
      (x: rect.right, y: rect.bottom),
      (x: rect.left, y: rect.bottom),
    ];
  }

  /// Midpoints of each triangle edge (apex→right, right→left, left→apex).
  static List<({double x, double y})> triangleEdgeMidpoints(
    NormalizedRect rect,
  ) {
    final v = triangleVertices(rect);
    return [
      midpoint(x0: v[0].x, y0: v[0].y, x1: v[1].x, y1: v[1].y),
      midpoint(x0: v[1].x, y0: v[1].y, x1: v[2].x, y1: v[2].y),
      midpoint(x0: v[2].x, y0: v[2].y, x1: v[0].x, y1: v[0].y),
    ];
  }

  /// Segment intersection in normalized plane, or null if parallel / miss.
  static ({double x, double y})? segmentIntersection({
    required double ax,
    required double ay,
    required double bx,
    required double by,
    required double cx,
    required double cy,
    required double dx,
    required double dy,
  }) {
    final rx = bx - ax;
    final ry = by - ay;
    final sx = dx - cx;
    final sy = dy - cy;
    final denom = rx * sy - ry * sx;
    if (denom.abs() < 1e-12) return null;
    final t = ((cx - ax) * sy - (cy - ay) * sx) / denom;
    final u = ((cx - ax) * ry - (cy - ay) * rx) / denom;
    if (t < 0 || t > 1 || u < 0 || u > 1) return null;
    return (x: ax + t * rx, y: ay + t * ry);
  }

  static String describe(
    NormalizedRect rect,
    StudioFrameShape shape,
  ) {
    switch (shape) {
      case StudioFrameShape.rectangle:
        final mids = rectangleEdgeMidpoints(rect);
        return 'shape: rectangle\n'
            '${rect.labeledText}\n'
            'mid.top: ${mids[0].x.toStringAsFixed(4)}, ${mids[0].y.toStringAsFixed(4)}\n'
            'mid.right: ${mids[1].x.toStringAsFixed(4)}, ${mids[1].y.toStringAsFixed(4)}\n'
            'mid.bottom: ${mids[2].x.toStringAsFixed(4)}, ${mids[2].y.toStringAsFixed(4)}\n'
            'mid.left: ${mids[3].x.toStringAsFixed(4)}, ${mids[3].y.toStringAsFixed(4)}';
      case StudioFrameShape.circle:
        final c = circleFromBounds(rect);
        return 'shape: circle\n'
            'cx: ${c.cx.toStringAsFixed(4)}\n'
            'cy: ${c.cy.toStringAsFixed(4)}\n'
            'radius: ${c.radius.toStringAsFixed(4)}';
      case StudioFrameShape.triangle:
        final v = triangleVertices(rect);
        final m = triangleEdgeMidpoints(rect);
        return 'shape: triangle\n'
            'apex: ${v[0].x.toStringAsFixed(4)}, ${v[0].y.toStringAsFixed(4)}\n'
            'right: ${v[1].x.toStringAsFixed(4)}, ${v[1].y.toStringAsFixed(4)}\n'
            'left: ${v[2].x.toStringAsFixed(4)}, ${v[2].y.toStringAsFixed(4)}\n'
            'mid.apexRight: ${m[0].x.toStringAsFixed(4)}, ${m[0].y.toStringAsFixed(4)}\n'
            'mid.base: ${m[1].x.toStringAsFixed(4)}, ${m[1].y.toStringAsFixed(4)}\n'
            'mid.apexLeft: ${m[2].x.toStringAsFixed(4)}, ${m[2].y.toStringAsFixed(4)}';
    }
  }
}
