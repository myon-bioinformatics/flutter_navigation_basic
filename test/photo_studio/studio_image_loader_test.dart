import 'dart:typed_data';

import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_image_loader.dart';
import 'package:flutter_test/flutter_test.dart';

final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// IHDR claims 10000×10000 without a full raster payload.
final _oversizedClaimPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 39, 16,
  0, 0, 39, 16, 8, 2, 0, 0, 0, 53, 44, 245, 112, 0, 0, 0, 9, 73, 68, 65, 84,
  120, 156, 99, 0, 0, 0, 1, 0, 1, 94, 255, 125, 249, 0, 0, 0, 0, 73, 69, 78,
  68, 174, 66, 96, 130,
]);

void main() {
  group('loadStudioImageBytes', () {
    test('accepts PNG screenshot bytes', () async {
      final loaded = await loadStudioImageBytes(_tinyPng);
      expect(loaded, isNotNull);
      expect(loaded, _tinyPng);
    });

    test('rejects empty bytes', () async {
      expect(await loadStudioImageBytes(Uint8List(0)), isNull);
    });

    test('rejects corrupt bytes without adapter', () async {
      final junk = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
      expect(await loadStudioImageBytes(junk), isNull);
    });

    test('uses native adapter then validates PNG output', () async {
      final junk = Uint8List.fromList([0x00, 0x01, 0x02]);
      final loaded = await loadStudioImageBytes(
        junk,
        nativeDecodeAdapter: (_) async => _tinyPng,
      );
      expect(loaded, _tinyPng);
    });

    test('rejects adapter output that is still undecodable', () async {
      final junk = Uint8List.fromList([0x00, 0x01, 0x02]);
      final loaded = await loadStudioImageBytes(
        junk,
        nativeDecodeAdapter: (_) async => Uint8List.fromList([9, 9, 9]),
      );
      expect(loaded, isNull);
    });

    test('readEncodedImageSize probes IHDR before full raster', () async {
      final size = await readEncodedImageSize(_oversizedClaimPng);
      expect(size, isNotNull);
      expect(size!.width, 10000);
      expect(size.height, 10000);
      expect(
        PhotoImportGate.rejectDecodedSize(
          width: size.width,
          height: size.height,
        ),
        PhotoImportRejection.tooManyPixels,
      );
    });
  });
}
