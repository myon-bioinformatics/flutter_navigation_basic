import 'dart:convert';
import 'dart:math' as math;

class BoundingBox {
  const BoundingBox({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.wrapsAntimeridian,
  });

  static const double _earthRadiusMeters = 6371008.8;

  final double south;
  final double west;
  final double north;
  final double east;
  final bool wrapsAntimeridian;

  static BoundingBox fromBounds({
    required String south,
    required String west,
    required String north,
    required String east,
  }) {
    final s = _parseFinite(south, 'South');
    final w = _parseFinite(west, 'West');
    final n = _parseFinite(north, 'North');
    final e = _parseFinite(east, 'East');

    if (s < -90 || s > 90 || n < -90 || n > 90) {
      throw const FormatException('Latitude bounds must be between -90 and 90.');
    }
    if (w < -180 || w > 180 || e < -180 || e > 180) {
      throw const FormatException('Longitude bounds must be between -180 and 180.');
    }
    if (s > n) {
      throw const FormatException('South must be less than or equal to north.');
    }

    return BoundingBox(
      south: s,
      west: w,
      north: n,
      east: e,
      wrapsAntimeridian: w > e,
    );
  }

  factory BoundingBox.fromCenterRadius({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw const FormatException('Latitude must be between -90 and 90.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw const FormatException('Longitude must be between -180 and 180.');
    }
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw const FormatException('Radius must be greater than zero.');
    }

    final angular = radiusMeters / _earthRadiusMeters;
    final latitudeDelta = _degrees(angular);
    final south = math.max(-90.0, latitude - latitudeDelta);
    final north = math.min(90.0, latitude + latitudeDelta);

    if (south <= -90 || north >= 90) {
      return BoundingBox(
        south: south,
        west: -180,
        north: north,
        east: 180,
        wrapsAntimeridian: false,
      );
    }

    final longitudeDelta = math.min(
      180.0,
      _degrees(angular / math.cos(_radians(latitude)).abs()),
    );
    final rawWest = longitude - longitudeDelta;
    final rawEast = longitude + longitudeDelta;
    final wraps = longitudeDelta < 180 && (rawWest < -180 || rawEast > 180);

    return BoundingBox(
      south: south,
      west: _normalizeLongitude(rawWest),
      north: north,
      east: _normalizeLongitude(rawEast),
      wrapsAntimeridian: wraps,
    );
  }

  double get centerLatitude => (south + north) / 2;

  double get centerLongitude {
    if (!wrapsAntimeridian) return (west + east) / 2;
    return _normalizeLongitude((west + east + 360) / 2);
  }

  double get latitudeSpan => north - south;

  double get longitudeSpan => wrapsAntimeridian
      ? (180 - west) + (east + 180)
      : east - west;

  String get labeledText =>
      'south: ${south.toStringAsFixed(6)}\n'
      'west: ${west.toStringAsFixed(6)}\n'
      'north: ${north.toStringAsFixed(6)}\n'
      'east: ${east.toStringAsFixed(6)}\n'
      'wraps_antimeridian: $wrapsAntimeridian';

  String get bboxText =>
      '[${west.toStringAsFixed(6)}, ${south.toStringAsFixed(6)}, '
      '${east.toStringAsFixed(6)}, ${north.toStringAsFixed(6)}]';

  String get jsonText => const JsonEncoder.withIndent('  ').convert({
        'south': south,
        'west': west,
        'north': north,
        'east': east,
        'wraps_antimeridian': wrapsAntimeridian,
        'center': {
          'latitude': centerLatitude,
          'longitude': centerLongitude,
        },
      });

  static double _parseFinite(String raw, String label) {
    final value = double.tryParse(raw.trim());
    if (value == null || !value.isFinite) {
      throw FormatException('$label must be a finite number.');
    }
    return value;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
  static double _degrees(double radians) => radians * 180 / math.pi;

  static double _normalizeLongitude(double longitude) {
    var value = longitude;
    while (value < -180) {
      value += 360;
    }
    while (value > 180) {
      value -= 360;
    }
    return value;
  }
}
