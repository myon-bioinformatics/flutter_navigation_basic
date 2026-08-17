import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/coordinate_formatter.dart';

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
}
