import 'dart:math' as math;

import 'normalized_rect.dart';
import 'studio_frame_style.dart';

/// Geometry helpers for photo-studio frames.
///
/// Midpoints and triangle/circle derived points are asserted by Dart unit tests
/// (`test/photo_studio/studio_geometry_test.dart`).
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

  /// Whether normalized point ([x], [y]) lies inside [shape] for [rect].
  ///
  /// [slop] expands the hit area slightly (stroke grab). Transparent corners
  /// of circles/triangles are not treated as hits.
  static bool shapeContainsNormalized(
    NormalizedRect rect,
    StudioFrameShape shape,
    double x,
    double y, {
    double slop = 0,
  }) {
    switch (shape) {
      case StudioFrameShape.rectangle:
        return x >= rect.left - slop &&
            x <= rect.right + slop &&
            y >= rect.top - slop &&
            y <= rect.bottom + slop;
      case StudioFrameShape.circle:
        final c = circleFromBounds(rect);
        final dx = x - c.cx;
        final dy = y - c.cy;
        final r = c.radius + slop;
        return dx * dx + dy * dy <= r * r;
      case StudioFrameShape.triangle:
        final v = triangleVertices(rect);
        if (_pointInTriangle(
          x,
          y,
          v[0].x,
          v[0].y,
          v[1].x,
          v[1].y,
          v[2].x,
          v[2].y,
        )) {
          return true;
        }
        if (slop <= 0) return false;
        return _distanceToSegment(x, y, v[0].x, v[0].y, v[1].x, v[1].y) <=
                slop ||
            _distanceToSegment(x, y, v[1].x, v[1].y, v[2].x, v[2].y) <=
                slop ||
            _distanceToSegment(x, y, v[2].x, v[2].y, v[0].x, v[0].y) <= slop;
    }
  }

  static bool _pointInTriangle(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final v0x = cx - ax;
    final v0y = cy - ay;
    final v1x = bx - ax;
    final v1y = by - ay;
    final v2x = px - ax;
    final v2y = py - ay;
    final dot00 = v0x * v0x + v0y * v0y;
    final dot01 = v0x * v1x + v0y * v1y;
    final dot02 = v0x * v2x + v0y * v2y;
    final dot11 = v1x * v1x + v1y * v1y;
    final dot12 = v1x * v2x + v1y * v2y;
    final denom = dot00 * dot11 - dot01 * dot01;
    if (denom.abs() < 1e-12) return false;
    final u = (dot11 * dot02 - dot01 * dot12) / denom;
    final v = (dot00 * dot12 - dot01 * dot02) / denom;
    return u >= 0 && v >= 0 && (u + v) <= 1;
  }

  static double _distanceToSegment(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final abx = bx - ax;
    final aby = by - ay;
    final len2 = abx * abx + aby * aby;
    if (len2 < 1e-12) {
      final dx = px - ax;
      final dy = py - ay;
      return math.sqrt(dx * dx + dy * dy);
    }
    var t = ((px - ax) * abx + (py - ay) * aby) / len2;
    t = t.clamp(0.0, 1.0);
    final dx = px - (ax + t * abx);
    final dy = py - (ay + t * aby);
    return math.sqrt(dx * dx + dy * dy);
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
