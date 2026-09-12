import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared with `tool/python/tests/test_photo_studio_geometry.py`.
/// Dart is the primary CI assertion; Python remains an optional cross-check.
const _fixturePath =
    'tool/python/fixtures/photo_studio_geometry_cases.json';

Map<String, dynamic> _loadFixture() {
  final raw = File(_fixturePath).readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

NormalizedRect _bounds(Map<String, dynamic> caseMap) {
  final b = caseMap['bounds'] as Map<String, dynamic>;
  return NormalizedRect(
    left: (b['left'] as num).toDouble(),
    top: (b['top'] as num).toDouble(),
    right: (b['right'] as num).toDouble(),
    bottom: (b['bottom'] as num).toDouble(),
  );
}

void main() {
  final payload = _loadFixture();
  final cases = payload['cases'] as List<dynamic>;

  for (final entry in cases) {
    final caseMap = entry as Map<String, dynamic>;
    final id = caseMap['photoStudioGeometryCaseId'] as String;
    final box = _bounds(caseMap);

    test('$id rectangle edge midpoints match shared fixtures', () {
      final expected = caseMap['expected_rect_midpoints'] as List<dynamic>;
      final mids = StudioGeometry.rectangleEdgeMidpoints(box);
      expect(mids.length, expected.length);
      for (var i = 0; i < mids.length; i++) {
        final e = expected[i] as Map<String, dynamic>;
        expect(mids[i].x, closeTo((e['x'] as num).toDouble(), 1e-9), reason: id);
        expect(mids[i].y, closeTo((e['y'] as num).toDouble(), 1e-9), reason: id);
      }
    });

    test('$id circle from bounds matches shared fixtures', () {
      final expected = caseMap['expected_circle'] as Map<String, dynamic>;
      final c = StudioGeometry.circleFromBounds(box);
      expect(c.cx, closeTo((expected['cx'] as num).toDouble(), 1e-9));
      expect(c.cy, closeTo((expected['cy'] as num).toDouble(), 1e-9));
      expect(c.radius, closeTo((expected['radius'] as num).toDouble(), 1e-9));
    });

    test('$id triangle vertices and midpoints match shared fixtures', () {
      final expectedVerts =
          caseMap['expected_triangle_vertices'] as List<dynamic>;
      final expectedMids =
          caseMap['expected_triangle_midpoints'] as List<dynamic>;
      final v = StudioGeometry.triangleVertices(box);
      final m = StudioGeometry.triangleEdgeMidpoints(box);
      expect(v.length, expectedVerts.length);
      expect(m.length, expectedMids.length);
      for (var i = 0; i < v.length; i++) {
        final e = expectedVerts[i] as Map<String, dynamic>;
        expect(v[i].x, closeTo((e['x'] as num).toDouble(), 1e-9));
        expect(v[i].y, closeTo((e['y'] as num).toDouble(), 1e-9));
      }
      for (var i = 0; i < m.length; i++) {
        final e = expectedMids[i] as Map<String, dynamic>;
        expect(m[i].x, closeTo((e['x'] as num).toDouble(), 1e-9));
        expect(m[i].y, closeTo((e['y'] as num).toDouble(), 1e-9));
      }
    });

    test('$id expected_crossing matches diagonal intersection when present', () {
      final crossing = caseMap['expected_crossing'];
      if (crossing == null) return;
      final e = crossing as Map<String, dynamic>;
      final hit = StudioGeometry.segmentIntersection(
        ax: box.left,
        ay: box.top,
        bx: box.right,
        by: box.bottom,
        cx: box.left,
        cy: box.bottom,
        dx: box.right,
        dy: box.top,
      );
      expect(hit, isNotNull);
      expect(hit!.x, closeTo((e['x'] as num).toDouble(), 1e-9));
      expect(hit.y, closeTo((e['y'] as num).toDouble(), 1e-9));
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

  test('fixture case ids are unique', () {
    final ids = [
      for (final entry in cases)
        (entry as Map<String, dynamic>)['photoStudioGeometryCaseId'] as String,
    ];
    expect(ids.toSet().length, ids.length);
  });
}
