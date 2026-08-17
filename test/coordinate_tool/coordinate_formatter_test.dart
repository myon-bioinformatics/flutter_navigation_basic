import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_navigation_basic/features/coordinate_tool/domain/coordinate_formatter.dart';

void main() {
  group('CoordinateValue', () {
    test('parses valid decimal coordinates', () {
      final value = CoordinateValue.parse(
        latitude: '35.681236',
        longitude: '139.767125',
      );

      expect(value.decimalDegrees, '35.681236, 139.767125');
      expect(value.dms, contains('N'));
      expect(value.dms, contains('E'));
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
  });
}
