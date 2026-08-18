import 'package:flutter_application_1/features/bounding_box/domain/bounding_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoundingBox', () {
    test('parses ordinary manual bounds and derives center/span', () {
      final box = BoundingBox.fromBounds(
        south: '35.67',
        west: '139.75',
        north: '35.69',
        east: '139.78',
      );

      expect(box.wrapsAntimeridian, isFalse);
      expect(box.centerLatitude, closeTo(35.68, 1e-9));
      expect(box.centerLongitude, closeTo(139.765, 1e-9));
      expect(box.latitudeSpan, closeTo(0.02, 1e-9));
      expect(box.longitudeSpan, closeTo(0.03, 1e-9));
      expect(box.bboxText, '[139.750000, 35.670000, 139.780000, 35.690000]');
    });

    test('allows antimeridian crossing when west is greater than east', () {
      final box = BoundingBox.fromBounds(
        south: '-10',
        west: '170',
        north: '10',
        east: '-170',
      );

      expect(box.wrapsAntimeridian, isTrue);
      expect(box.longitudeSpan, 20);
      expect(box.centerLongitude.abs(), 180);
    });

    test('generates meter-based bounds from a center and radius', () {
      final box = BoundingBox.fromCenterRadius(
        latitude: 35.681236,
        longitude: 139.767125,
        radiusMeters: 1000,
      );

      expect(box.south, lessThan(35.681236));
      expect(box.north, greaterThan(35.681236));
      expect(box.west, lessThan(139.767125));
      expect(box.east, greaterThan(139.767125));
      expect(box.wrapsAntimeridian, isFalse);
    });

    test('uses full longitude range when generated box reaches a pole', () {
      final box = BoundingBox.fromCenterRadius(
        latitude: 89.9999,
        longitude: 20,
        radiusMeters: 1000,
      );

      expect(box.north, 90);
      expect(box.west, -180);
      expect(box.east, 180);
      expect(box.wrapsAntimeridian, isFalse);
    });

    test('rejects invalid ranges and non-finite values', () {
      expect(
        () => BoundingBox.fromBounds(
          south: '20',
          west: '0',
          north: '10',
          east: '1',
        ),
        throwsFormatException,
      );
      expect(
        () => BoundingBox.fromBounds(
          south: 'NaN',
          west: '0',
          north: '10',
          east: '1',
        ),
        throwsFormatException,
      );
      expect(
        () => BoundingBox.fromCenterRadius(
          latitude: 0,
          longitude: 0,
          radiusMeters: 0,
        ),
        throwsFormatException,
      );
    });

    test('JSON includes center and antimeridian metadata', () {
      final box = BoundingBox.fromBounds(
        south: '-10',
        west: '170',
        north: '10',
        east: '-170',
      );

      expect(box.jsonText, contains('"wraps_antimeridian": true'));
      expect(box.jsonText, contains('"center"'));
    });
  });
}
