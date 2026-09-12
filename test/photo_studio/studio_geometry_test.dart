import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const box = NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8);

  test('rectangle edge midpoints match Python oracle fixtures', () {
    final mids = StudioGeometry.rectangleEdgeMidpoints(box);
    expect(mids[0].x, closeTo(0.5, 1e-9));
    expect(mids[0].y, closeTo(0.2, 1e-9));
    expect(mids[1].x, closeTo(0.8, 1e-9));
    expect(mids[1].y, closeTo(0.5, 1e-9));
    expect(mids[2].x, closeTo(0.5, 1e-9));
    expect(mids[2].y, closeTo(0.8, 1e-9));
    expect(mids[3].x, closeTo(0.2, 1e-9));
    expect(mids[3].y, closeTo(0.5, 1e-9));
  });

  test('circle from bounds uses shorter side as diameter', () {
    final c = StudioGeometry.circleFromBounds(box);
    expect(c.cx, closeTo(0.5, 1e-9));
    expect(c.cy, closeTo(0.5, 1e-9));
    expect(c.radius, closeTo(0.3, 1e-9));
  });

  test('triangle vertices and edge midpoints are derived from the box', () {
    final v = StudioGeometry.triangleVertices(box);
    expect(v[0].x, closeTo(0.5, 1e-9));
    expect(v[0].y, closeTo(0.2, 1e-9));
    expect(v[1].x, closeTo(0.8, 1e-9));
    expect(v[1].y, closeTo(0.8, 1e-9));
    expect(v[2].x, closeTo(0.2, 1e-9));
    expect(v[2].y, closeTo(0.8, 1e-9));

    final m = StudioGeometry.triangleEdgeMidpoints(box);
    expect(m[1].x, closeTo(0.5, 1e-9));
    expect(m[1].y, closeTo(0.8, 1e-9));
  });

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
    expect(
      StudioGeometry.describe(box, StudioFrameShape.circle),
      contains('radius:'),
    );
    expect(
      StudioGeometry.describe(box, StudioFrameShape.triangle),
      contains('apex:'),
    );
  });
}
