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

  static String toDms(double value, {required bool isLatitude}) {
    final absolute = value.abs();
    var degrees = absolute.floor();
    final minuteValue = (absolute - degrees) * 60;
    var minutes = minuteValue.floor();
    var seconds = (minuteValue - minutes) * 60;

    // Keep the display normalized when rounding reaches 60 seconds.
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
