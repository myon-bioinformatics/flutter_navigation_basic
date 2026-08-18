import 'dart:math' as math;

class CoordinateValue {
  const CoordinateValue({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  static CoordinateValue parse({
    required String latitude,
    required String longitude,
  }) {
    final lat = double.tryParse(latitude.trim());
    final lon = double.tryParse(longitude.trim());
    if (lat == null || lon == null) {
      throw const FormatException('Latitude and longitude must be numbers.');
    }
    if (!lat.isFinite || !lon.isFinite) {
      throw const FormatException('Latitude and longitude must be finite numbers.');
    }
    if (lat < -90 || lat > 90) {
      throw const FormatException('Latitude must be between -90 and 90.');
    }
    if (lon < -180 || lon > 180) {
      throw const FormatException('Longitude must be between -180 and 180.');
    }
    return CoordinateValue(latitude: lat, longitude: lon);
  }

  String get decimalDegrees =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get dms => '${toDms(latitude, isLatitude: true)}, '
      '${toDms(longitude, isLatitude: false)}';

  CoordinateToleranceArea toleranceArea(double radiusMeters) {
    return CoordinateToleranceArea.fromCenter(
      center: this,
      radiusMeters: radiusMeters,
    );
  }

  XyzTile xyzTile(int zoom) => XyzTile.fromCoordinate(this, zoom);

  static String toDms(double value, {required bool isLatitude}) {
    final absolute = value.abs();
    var degrees = absolute.floor();
    final minuteValue = (absolute - degrees) * 60;
    var minutes = minuteValue.floor();
    var seconds = (minuteValue - minutes) * 60;

    seconds = double.parse(seconds.toStringAsFixed(2));
    if (seconds >= 60) {
      seconds = 0;
      minutes += 1;
      if (minutes >= 60) {
        minutes = 0;
        degrees += 1;
      }
    }

    final hemisphere = isLatitude
        ? (value < 0 ? 'S' : 'N')
        : (value < 0 ? 'W' : 'E');
    return '$degrees° ${minutes.toString().padLeft(2, '0')}′ '
        '${seconds.toStringAsFixed(2).padLeft(5, '0')}″ $hemisphere';
  }
}

enum CoordinateTolerancePreset {
  exactGps('Exact / GPS', 25),
  building('Building / Facility', 100),
  stationCampus('Station / Campus', 350),
  park('Park / Large facility', 1000),
  district('District / Loose area', 3000),
  custom('Custom', null);

  const CoordinateTolerancePreset(this.label, this.radiusMeters);

  final String label;
  final double? radiusMeters;
}

class CoordinateToleranceArea {
  const CoordinateToleranceArea({
    required this.center,
    required this.radiusMeters,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.wrapsAntimeridian,
  });

  static const double _earthRadiusMeters = 6371008.8;

  final CoordinateValue center;
  final double radiusMeters;
  final double south;
  final double west;
  final double north;
  final double east;
  final bool wrapsAntimeridian;

  factory CoordinateToleranceArea.fromCenter({
    required CoordinateValue center,
    required double radiusMeters,
  }) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw const FormatException('Tolerance radius must be greater than zero.');
    }

    final angular = radiusMeters / _earthRadiusMeters;
    final latitudeRadians = _toRadians(center.latitude);
    final latitudeDelta = _toDegrees(angular);
    final south = math.max(-90.0, center.latitude - latitudeDelta);
    final north = math.min(90.0, center.latitude + latitudeDelta);

    double longitudeDelta;
    if (south <= -90 || north >= 90 || latitudeRadians.cos().abs() < 1e-12) {
      longitudeDelta = 180;
    } else {
      longitudeDelta = _toDegrees(angular / latitudeRadians.cos().abs());
      longitudeDelta = math.min(180, longitudeDelta);
    }

    final rawWest = center.longitude - longitudeDelta;
    final rawEast = center.longitude + longitudeDelta;
    final west = _normalizeLongitude(rawWest);
    final east = _normalizeLongitude(rawEast);
    final wraps = longitudeDelta < 180 && (rawWest < -180 || rawEast > 180);

    return CoordinateToleranceArea(
      center: center,
      radiusMeters: radiusMeters,
      south: south,
      west: west,
      north: north,
      east: east,
      wrapsAntimeridian: wraps,
    );
  }

  String get centerRadiusText =>
      'center: ${center.decimalDegrees}\nradius_m: ${_formatRadius(radiusMeters)}';

  String get boundsText =>
      'south: ${south.toStringAsFixed(6)}\n'
      'west: ${west.toStringAsFixed(6)}\n'
      'north: ${north.toStringAsFixed(6)}\n'
      'east: ${east.toStringAsFixed(6)}\n'
      'wraps_antimeridian: $wrapsAntimeridian';

  String get bboxText =>
      '[${west.toStringAsFixed(6)}, ${south.toStringAsFixed(6)}, '
      '${east.toStringAsFixed(6)}, ${north.toStringAsFixed(6)}]';

  String get jsonText => '''{
  "center": {
    "latitude": ${center.latitude.toStringAsFixed(6)},
    "longitude": ${center.longitude.toStringAsFixed(6)}
  },
  "radius_m": ${_formatRadius(radiusMeters)},
  "bounds": {
    "south": ${south.toStringAsFixed(6)},
    "west": ${west.toStringAsFixed(6)},
    "north": ${north.toStringAsFixed(6)},
    "east": ${east.toStringAsFixed(6)},
    "wraps_antimeridian": $wrapsAntimeridian
  }
}''';

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;

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

  static String _formatRadius(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
}

class XyzTile {
  const XyzTile({required this.zoom, required this.x, required this.y});

  static const double _maxMercatorLatitude = 85.05112878;

  final int zoom;
  final int x;
  final int y;

  factory XyzTile.fromCoordinate(CoordinateValue coordinate, int zoom) {
    if (zoom < 0 || zoom > 22) {
      throw const FormatException('XYZ tile zoom must be between 0 and 22.');
    }
    final latitude = coordinate.latitude.clamp(
      -_maxMercatorLatitude,
      _maxMercatorLatitude,
    );
    final n = math.pow(2, zoom).toDouble();
    final x = (((coordinate.longitude + 180) / 360) * n)
        .floor()
        .clamp(0, n.toInt() - 1)
        .toInt();
    final latRad = latitude * math.pi / 180;
    final mercator = math.log(math.tan(math.pi / 4 + latRad / 2));
    final y = ((1 - mercator / math.pi) / 2 * n)
        .floor()
        .clamp(0, n.toInt() - 1)
        .toInt();
    return XyzTile(zoom: zoom, x: x, y: y);
  }

  String get path => '$zoom/$x/$y';
  String get text => 'z: $zoom\nx: $x\ny: $y\npath: $path';
}
