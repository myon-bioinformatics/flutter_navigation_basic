import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_application_1/features/photo_studio/data/image_format_sniff.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _load(String name) =>
    File('test/fixtures/photo_studio/import_compat/$name').readAsBytesSync();

void main() {
  group('sniffImageFormat', () {
    test('png / jpeg / webp / gif', () {
      expect(
        sniffImageFormat(_load('png_opaque_2x2.png')).kind,
        ImageFormatKind.png,
      );
      expect(
        sniffImageFormat(_load('jpeg_baseline_markers_64x32.jpg')).kind,
        ImageFormatKind.jpeg,
      );
      expect(
        sniffImageFormat(_load('webp_lossy_64x32.webp')).kind,
        ImageFormatKind.webp,
      );
      expect(
        sniffImageFormat(_load('gif_still_1x1.gif')).kind,
        ImageFormatKind.gif,
      );
    });

    test('jpeg progressive + EXIF orientation 1-8', () {
      final progressive =
          sniffImageFormat(_load('jpeg_progressive_markers_64x32.jpg'));
      expect(progressive.kind, ImageFormatKind.jpeg);
      expect(progressive.jpegProgressive, isTrue);

      for (var o = 1; o <= 8; o++) {
        final sniff = sniffImageFormat(
          _load('jpeg_exif_orientation_${o}_markers_64x32.jpg'),
        );
        expect(sniff.kind, ImageFormatKind.jpeg);
        expect(sniff.jpegExifOrientation, o);
      }
    });

    test('HEIC brands, synthetic HEIC, AVIF ftyp', () {
      for (final brand in ['heic', 'heif', 'mif1', 'msf1', 'heix']) {
        final sniff = sniffImageFormat(_load('heic_ftyp_$brand.heic'));
        expect(sniff.kind, ImageFormatKind.heic, reason: brand);
        expect(sniff.brand, brand);
      }
      expect(
        sniffImageFormat(_load('heic_synthetic_markers_64x32.heic')).kind,
        ImageFormatKind.heic,
      );
      final avif = sniffImageFormat(_load('avif_ftyp_only.avif'));
      expect(avif.kind, ImageFormatKind.avif);
    });

    test('empty and unknown', () {
      expect(sniffImageFormat(Uint8List(0)).kind, ImageFormatKind.empty);
      expect(
        sniffImageFormat(Uint8List.fromList([1, 2, 3, 4])).kind,
        ImageFormatKind.unknown,
      );
    });
  });
}
