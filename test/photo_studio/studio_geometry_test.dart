import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}

class _GeometryCase {
  const _GeometryCase({
    required this.id,
    required this.bounds,
    required this.rectMidpoints,
    required this.circleCx,
    required this.circleCy,
    required this.circleRadius,
    required this.triangleVertices,
    required this.triangleMidpoints,
    this.crossing,
  });

  final String id;
  final NormalizedRect bounds;
  final List<_Point> rectMidpoints;
  final double circleCx;
  final double circleCy;
  final double circleRadius;
  final List<_Point> triangleVertices;
  final List<_Point> triangleMidpoints;
  final _Point? crossing;
}

/// Table-driven geometry cases kept in Dart (no Python fixture).
const _cases = <_GeometryCase>[
  _GeometryCase(
    id: 'centered-square',
    bounds: NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
    rectMidpoints: [
      _Point(0.5, 0.2),
      _Point(0.8, 0.5),
      _Point(0.5, 0.8),
      _Point(0.2, 0.5),
    ],
    circleCx: 0.5,
    circleCy: 0.5,
    circleRadius: 0.3,
    triangleVertices: [
      _Point(0.5, 0.2),
      _Point(0.8, 0.8),
      _Point(0.2, 0.8),
    ],
    triangleMidpoints: [
      _Point(0.65, 0.5),
      _Point(0.5, 0.8),
      _Point(0.35, 0.5),
    ],
    crossing: _Point(0.5, 0.5),
  ),
  _GeometryCase(
    id: 'wide-rect',
    bounds: NormalizedRect(left: 0.1, top: 0.25, right: 0.9, bottom: 0.55),
    rectMidpoints: [
      _Point(0.5, 0.25),
      _Point(0.9, 0.4),
      _Point(0.5, 0.55),
      _Point(0.1, 0.4),
    ],
    circleCx: 0.5,
    circleCy: 0.4,
    circleRadius: 0.15,
    triangleVertices: [
      _Point(0.5, 0.25),
      _Point(0.9, 0.55),
      _Point(0.1, 0.55),
    ],
    triangleMidpoints: [
      _Point(0.7, 0.4),
      _Point(0.5, 0.55),
      _Point(0.3, 0.4),
    ],
  ),
];

void main() {
  for (final c in _cases) {
    test('${c.id} rectangle edge midpoints', () {
      final mids = StudioGeometry.rectangleEdgeMidpoints(c.bounds);
      expect(mids.length, c.rectMidpoints.length);
      for (var i = 0; i < mids.length; i++) {
        expect(mids[i].x, closeTo(c.rectMidpoints[i].x, 1e-9), reason: c.id);
        expect(mids[i].y, closeTo(c.rectMidpoints[i].y, 1e-9), reason: c.id);
      }
    });

    test('${c.id} circle from bounds', () {
      final circle = StudioGeometry.circleFromBounds(c.bounds);
      expect(circle.cx, closeTo(c.circleCx, 1e-9));
      expect(circle.cy, closeTo(c.circleCy, 1e-9));
      expect(circle.radius, closeTo(c.circleRadius, 1e-9));
    });

    test('${c.id} triangle vertices and midpoints', () {
      final verts = StudioGeometry.triangleVertices(c.bounds);
      final mids = StudioGeometry.triangleEdgeMidpoints(c.bounds);
      expect(verts.length, c.triangleVertices.length);
      expect(mids.length, c.triangleMidpoints.length);
      for (var i = 0; i < verts.length; i++) {
        expect(verts[i].x, closeTo(c.triangleVertices[i].x, 1e-9));
        expect(verts[i].y, closeTo(c.triangleVertices[i].y, 1e-9));
      }
      for (var i = 0; i < mids.length; i++) {
        expect(mids[i].x, closeTo(c.triangleMidpoints[i].x, 1e-9));
        expect(mids[i].y, closeTo(c.triangleMidpoints[i].y, 1e-9));
      }
    });

    test('${c.id} diagonal crossing when present', () {
      final expected = c.crossing;
      if (expected == null) return;
      final hit = StudioGeometry.segmentIntersection(
        ax: c.bounds.left,
        ay: c.bounds.top,
        bx: c.bounds.right,
        by: c.bounds.bottom,
        cx: c.bounds.left,
        cy: c.bounds.bottom,
        dx: c.bounds.right,
        dy: c.bounds.top,
      );
      expect(hit, isNotNull);
      expect(hit!.x, closeTo(expected.x, 1e-9));
      expect(hit.y, closeTo(expected.y, 1e-9));
    });
  }

  test('segment intersection finds crossing center', () {
    final hit = StudioGeometry.segmentIntersection(
      ax: 0,
      ay: 0,
      bx: 1,
      by: 1,
      cx: 0,
      cy: 1,
      dx: 1,
      dy: 0,
    );
    expect(hit, isNotNull);
    expect(hit!.x, closeTo(0.5, 1e-9));
    expect(hit.y, closeTo(0.5, 1e-9));
  });

  test('describe includes shape-specific fields', () {
    const box = NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8);
    expect(
      StudioGeometry.describe(box, StudioFrameShape.circle),
      contains('radius:'),
    );
    expect(
      StudioGeometry.describe(box, StudioFrameShape.triangle),
      contains('apex:'),
    );
  });

  test('case ids are unique', () {
    final ids = [for (final c in _cases) c.id];
    expect(ids.toSet().length, ids.length);
  });
}
