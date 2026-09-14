import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/utils/ascii_fullwidth.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/bounding_box.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/coordinate_formatter.dart';
import 'package:flutter_application_1/shared/input/ascii_fullwidth_text_input_formatter.dart';

void main() {
  group('normalizeAsciiFullwidth', () {
    test('maps fullwidth digits and punctuation', () {
      expect(normalizeAsciiFullwidth('３５．６８１２３６'), '35.681236');
    });

    test('maps fullwidth and math minus to ASCII hyphen', () {
      expect(normalizeAsciiFullwidth('－９０'), '-90');
      expect(normalizeAsciiFullwidth('−９０'), '-90');
    });

    test('maps fullwidth URL characters', () {
      const full =
          'ｈｔｔｐｓ：／／ｍａｐｓ．ｇｏｏｇｌｅ．ｃｏｍ／？ｑ＝３５．６，１３９．７';
      const ascii = 'https://maps.google.com/?q=35.6,139.7';
      expect(normalizeAsciiFullwidth(full), ascii);
      expect(containsFullwidthDigits(normalizeAsciiFullwidth(full)), isFalse);
    });

    test('leaves plain ASCII unchanged', () {
      const ascii = 'https://maps.google.com/?q=35.6,139.7';
      expect(normalizeAsciiFullwidth(ascii), ascii);
    });

    test('maps ideographic space', () {
      expect(normalizeAsciiFullwidth('３５　６'), '35 6');
    });
  });

  group('parse helpers', () {
    test('tryParseAsciiDouble accepts fullwidth lat/lon', () {
      expect(tryParseAsciiDouble('３５．６８１２３６'), 35.681236);
      expect(tryParseAsciiDouble('－９０'), -90);
      expect(tryParseAsciiDouble('−９０'), -90);
    });

    test('tryParseAsciiUri accepts fullwidth maps URL', () {
      final uri = tryParseAsciiUri(
        'ｈｔｔｐｓ：／／ｍａｐｓ．ｇｏｏｇｌｅ．ｃｏｍ／？ｑ＝３５．６，１３９．７',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'maps.google.com');
      expect(uri.queryParameters['q'], '35.6,139.7');
    });
  });

  group('CoordinateValue / BoundingBox boundaries', () {
    test('CoordinateValue.parse accepts fullwidth digits', () {
      final value = CoordinateValue.parse(
        latitude: '３５．６８１２３６',
        longitude: '１３９．７６７１２５',
      );
      expect(value.latitude, closeTo(35.681236, 1e-9));
      expect(value.longitude, closeTo(139.767125, 1e-9));
      expect(containsFullwidthDigits(value.decimalDegrees), isFalse);
      expect(containsFullwidthDigits(value.googleMapsUri.toString()), isFalse);
    });

    test('BoundingBox.fromBounds accepts fullwidth digits', () {
      final box = BoundingBox.fromBounds(
        south: '３５．６７６７４６',
        west: '１３９．７５６０６０',
        north: '３５．６８５７２６',
        east: '１３９．７７８１９０',
      );
      expect(box.south, closeTo(35.676746, 1e-9));
      expect(containsFullwidthDigits(box.bboxText), isFalse);
    });

    test('tryParseMapsUrl accepts fullwidth share URL', () {
      final value = CoordinateValue.tryParseMapsUrl(
        'ｈｔｔｐｓ：／／ｗｗｗ．ｇｏｏｇｌｅ．ｃｏｍ／ｍａｐｓ／？ｑ＝３５．６，１３９．７',
      );
      expect(value, isNotNull);
      expect(value!.latitude, closeTo(35.6, 1e-9));
      expect(value.longitude, closeTo(139.7, 1e-9));
    });
  });

  group('AsciiFullwidthTextInputFormatter', () {
    const formatter = AsciiFullwidthTextInputFormatter();

    test('normalizes paste while preserving selection offsets', () {
      final next = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '３５．６',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(next.text, '35.6');
      expect(next.selection.baseOffset, 4);
      expect(containsFullwidthDigits(next.text), isFalse);
    });

    test('is a no-op for ASCII', () {
      const value = TextEditingValue(
        text: '35.6',
        selection: TextSelection.collapsed(offset: 4),
      );
      final next = formatter.formatEditUpdate(value, value);
      expect(identical(next, value), isTrue);
    });
  });
}
