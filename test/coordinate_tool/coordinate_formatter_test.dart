import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/coordinate_tool/domain/coordinate_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateValue', () {
    test('parses valid decimal coordinates with exact DMS output', () {
      final value = CoordinateValue.parse(
        latitude: '35.681236',
        longitude: '139.767125',
      );

      expect(value.decimalDegrees, '35.681236, 139.767125');
      expect(value.dms, '35° 40′ 52.45″ N, 139° 46′ 01.65″ E');
    });

    test('uses south and west hemispheres for negative values', () {
      final value = CoordinateValue.parse(
        latitude: '-33.8688',
        longitude: '-70.6693',
      );

      expect(value.dms, contains('S'));
      expect(value.dms, contains('W'));
    });

    test('accepts coordinate boundaries', () {
      expect(
        CoordinateValue.parse(latitude: '90', longitude: '180'),
        isA<CoordinateValue>(),
      );
      expect(
        CoordinateValue.parse(latitude: '-90', longitude: '-180'),
        isA<CoordinateValue>(),
      );
    });

    test('normalizes DMS rounding carry into the next degree', () {
      expect(
        CoordinateValue.toDms(179.999999999996, isLatitude: false),
        '180° 00′ 00.00″ E',
      );
    });

    test('rejects out-of-range coordinates', () {
      expect(
        () => CoordinateValue.parse(latitude: '90.1', longitude: '0'),
        throwsFormatException,
      );
      expect(
        () => CoordinateValue.parse(latitude: '0', longitude: '180.1'),
        throwsFormatException,
      );
    });

    test('rejects non-numeric values', () {
      expect(
        () => CoordinateValue.parse(latitude: 'north', longitude: 'east'),
        throwsFormatException,
      );
    });

    test('rejects non-finite values', () {
      expect(
        () => CoordinateValue.parse(latitude: 'NaN', longitude: '0'),
        throwsFormatException,
      );
      expect(
        () => CoordinateValue.parse(latitude: '0', longitude: 'Infinity'),
        throwsFormatException,
      );
    });
  });

  group('CoordinateToleranceArea', () {
    const center = CoordinateValue(latitude: 35.681236, longitude: 139.767125);

    test('presets provide intentionally loose real-world radii', () {
      expect(CoordinateTolerancePreset.exactGps.radiusMeters, 25);
      expect(CoordinateTolerancePreset.building.radiusMeters, 100);
      expect(CoordinateTolerancePreset.stationCampus.radiusMeters, 350);
      expect(CoordinateTolerancePreset.park.radiusMeters, 1000);
      expect(CoordinateTolerancePreset.district.radiusMeters, 3000);
      expect(CoordinateTolerancePreset.custom.radiusMeters, isNull);
    });

    test('builds meter-based bounds around the center', () {
      final area = center.toleranceArea(100);

      expect(area.south, lessThan(center.latitude));
      expect(area.north, greaterThan(center.latitude));
      expect(area.west, lessThan(center.longitude));
      expect(area.east, greaterThan(center.longitude));
      expect(area.wrapsAntimeridian, isFalse);

      final latitudeHalfSpan = area.north - center.latitude;
      final longitudeHalfSpan = area.east - center.longitude;
      expect(latitudeHalfSpan, closeTo(0.000899, 0.00001));
      expect(longitudeHalfSpan, greaterThan(latitudeHalfSpan));
      expect(area.centerRadiusText, contains('radius_m: 100'));
      expect(area.jsonText, contains('"wraps_antimeridian": false'));
      expect(
        center.googleMapsUri.toString(),
        contains('https://www.google.com/maps/search/?api=1'),
      );
      expect(center.googleMapsUri.toString(), contains('35.681236%2C139.767125'));
      expect(center.appleMapsUri.toString(), contains('https://maps.apple.com/?'));
      expect(center.appleMapsUri.toString(), contains('ll=35.681236%2C139.767125'));
    });

    test('emits directly usable Google Maps and Apple MapKit circle snippets', () {
      final area = center.toleranceArea(350);

      expect(area.googleMapsJavaScript, '''new google.maps.Circle({
  center: {
    lat: 35.681236,
    lng: 139.767125
  },
  radius: 350
});''');
      expect(area.appleMapKitSwift, '''MKCircle(
  center: CLLocationCoordinate2D(
    latitude: 35.681236,
    longitude: 139.767125
  ),
  radius: 350
)''');
    });

    test('builds copy-paste Google and Apple area viewport URLs', () {
      final area = center.toleranceArea(100);

      expect(
        area.googleMapsAreaUri.toString(),
        'https://www.google.com/maps/@35.681236,139.767125,16z',
      );
      expect(area.appleMapsAreaUri.toString(), contains('https://maps.apple.com/?'));
      expect(area.appleMapsAreaUri.queryParameters['ll'], '35.681236,139.767125');
      expect(area.appleMapsAreaUri.queryParameters['spn'], isNotNull);
      expect(area.appleMapsAreaUri.queryParameters['q'], 'Tolerance area');
    });

    test('emits Google Rectangle and Apple MKCoordinateRegion snippets', () {
      final area = center.toleranceArea(100);

      expect(area.googleMapsRectangleJavaScript, contains('new google.maps.Rectangle({'));
      expect(area.googleMapsRectangleJavaScript, contains('south: ${area.south.toStringAsFixed(6)}'));
      expect(area.appleMapKitRegionSwift, contains('MKCoordinateRegion('));
      expect(area.appleMapKitRegionSwift, contains('MKCoordinateSpan('));
      expect(
        area.appleMapKitRegionSwift,
        contains('latitudeDelta: ${(area.north - area.south).abs().toStringAsFixed(6)}'),
      );
    });

    test('omits Apple Maps spn when the area wraps the antimeridian', () {
      const nearDateLine = CoordinateValue(latitude: 0, longitude: 179.999);
      final area = nearDateLine.toleranceArea(1000);

      expect(area.wrapsAntimeridian, isTrue);
      expect(area.supportsAppleMapsSpan, isFalse);
      expect(area.appleMapsAreaUri.queryParameters.containsKey('spn'), isFalse);
    });

    test('omits Apple Maps spn when longitude spans the full world', () {
      const nearPole = CoordinateValue(latitude: 89.9999, longitude: 20);
      final area = nearPole.toleranceArea(1000);

      expect(area.spansFullLongitude, isTrue);
      expect(area.supportsAppleMapsSpan, isFalse);
      expect(area.appleMapsAreaUri.queryParameters.containsKey('spn'), isFalse);
      expect(
        CoordinateToleranceArea.zoomForRadiusMeters(
          1000,
          latitude: nearPole.latitude,
        ),
        3,
      );
    });

    test('uses latitude-aware Google Maps zoom at high latitudes', () {
      const arctic = CoordinateValue(latitude: 80, longitude: 0);
      final area = arctic.toleranceArea(100);

      expect(
        CoordinateToleranceArea.zoomForRadiusMeters(100, latitude: 0),
        greaterThan(
          CoordinateToleranceArea.zoomForRadiusMeters(100, latitude: 80),
        ),
      );
      expect(area.googleMapsAreaUri.toString(), endsWith(',14z'));
      expect(
        CoordinateToleranceArea.zoomForRadiusMeters(100, latitude: 85),
        13,
      );
    });

    test('matches shared golden vectors for zoom and span policy', () async {
      final raw = await File('tool/python/fixtures/coordinate_area_cases.json').readAsString();
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final cases = payload['cases'] as List<dynamic>;

      for (final entry in cases) {
        final caseMap = entry as Map<String, dynamic>;
        final value = CoordinateValue(
          latitude: (caseMap['latitude'] as num).toDouble(),
          longitude: (caseMap['longitude'] as num).toDouble(),
        );
        final radius = (caseMap['radius_m'] as num).toDouble();
        final area = value.toleranceArea(radius);

        expect(
          CoordinateToleranceArea.zoomForRadiusMeters(
            radius,
            latitude: value.latitude,
          ),
          caseMap['expected_zoom'],
          reason: caseMap['id'] as String,
        );
        expect(area.wrapsAntimeridian, caseMap['expect_antimeridian']);
        expect(area.spansFullLongitude, caseMap['expect_full_longitude']);
        expect(area.supportsAppleMapsSpan, caseMap['expect_apple_spn']);
        expect(
          area.appleMapsAreaUri.queryParameters.containsKey('spn'),
          caseMap['expect_apple_spn'],
        );
      }
    });

    test('marks bounds that cross the antimeridian', () {
      const nearDateLine = CoordinateValue(latitude: 0, longitude: 179.999);
      final area = nearDateLine.toleranceArea(1000);

      expect(area.wrapsAntimeridian, isTrue);
      expect(area.west, lessThan(180));
      expect(area.east, lessThan(0));
    });

    test('expands longitude to the full world when radius reaches a pole', () {
      const nearPole = CoordinateValue(latitude: 89.9999, longitude: 20);
      final area = nearPole.toleranceArea(1000);

      expect(area.north, 90);
      expect(area.west, -180);
      expect(area.east, 180);
      expect(area.wrapsAntimeridian, isFalse);
    });

    test('rejects invalid tolerance radii', () {
      expect(() => center.toleranceArea(0), throwsFormatException);
      expect(() => center.toleranceArea(-1), throwsFormatException);
      expect(() => center.toleranceArea(double.nan), throwsFormatException);
    });
  });

  group('XyzTile', () {
    const tokyoStation = CoordinateValue(
      latitude: 35.681236,
      longitude: 139.767125,
    );

    test('matches known Web Mercator XYZ tile coordinates', () {
      final tile = tokyoStation.xyzTile(16);

      expect(tile.zoom, 16);
      expect(tile.x, 58211);
      expect(tile.y, 25806);
      expect(tile.path, '16/58211/25806');
    });

    test('clamps polar latitudes to the Web Mercator limit', () {
      const northPole = CoordinateValue(latitude: 90, longitude: 0);
      final tile = northPole.xyzTile(2);

      expect(tile.x, inInclusiveRange(0, 3));
      expect(tile.y, 0);
    });

    test('rejects unsupported zoom levels', () {
      expect(() => tokyoStation.xyzTile(-1), throwsFormatException);
      expect(() => tokyoStation.xyzTile(23), throwsFormatException);
    });
  });
}
