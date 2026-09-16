import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/photo_studio/data/image_picker_photo_source.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_import_limits.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_image_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Uint8List _heicLike() {
  final heic = Uint8List(16);
  heic[4] = 0x66;
  heic[5] = 0x74;
  heic[6] = 0x79;
  heic[7] = 0x70;
  heic.setAll(8, 'heic'.codeUnits);
  return heic;
}

void main() {
  group('PhotoImportGate', () {
    test('rejects empty and oversized raw bytes', () {
      expect(
        PhotoImportGate.rejectRawBytes(Uint8List(0)),
        PhotoImportRejection.empty,
      );
      expect(
        PhotoImportGate.rejectRawBytes(
          Uint8List(PhotoImportLimits.maxInputBytes + 1),
        ),
        PhotoImportRejection.tooLargeBytes,
      );
      expect(PhotoImportGate.rejectRawBytes(_tinyPng), isNull);
    });

    test('rejects excessive pixel counts', () {
      expect(
        PhotoImportGate.rejectDecodedSize(width: 10000, height: 10000),
        PhotoImportRejection.tooManyPixels,
      );
      expect(
        PhotoImportGate.rejectDecodedSize(width: 100, height: 100),
        isNull,
      );
    });

    test('detects HEIC ftyp brands', () {
      expect(PhotoImportGate.looksLikeHeic(_heicLike()), isTrue);
      expect(PhotoImportGate.looksLikeHeic(_tinyPng), isFalse);
    });
  });

  group('ImagePickerPhotoSource', () {
    test('success returns bytes', () async {
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async => XFile.fromData(
          _tinyPng,
          name: 'a.png',
          mimeType: 'image/png',
        ),
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.success);
      expect(outcome.bytes, _tinyPng);
    });

    test('cancel returns cancelled', () async {
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async => null,
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.cancelled);
      expect(outcome.bytes, isNull);
    });

    test('missing plugin → unavailable', () async {
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async {
          throw MissingPluginException('no picker');
        },
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.unavailable);
    });

    test('permission denial → unavailable', () async {
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async {
          throw PlatformException(code: 'photo_access_denied', message: 'no');
        },
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.unavailable);
    });

    test('broken read → failed', () async {
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async => XFile.fromData(
          Uint8List(0),
          name: 'empty.png',
          mimeType: 'image/png',
        ),
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.failed);
    });
  });

  group('GalPhotoSink contract', () {
    test('PhotoSaveOutcome.ok only for saved', () {
      expect(const PhotoSaveOutcome.saved().ok, isTrue);
      expect(const PhotoSaveOutcome.unavailable().ok, isFalse);
      expect(const PhotoSaveOutcome.failed().ok, isFalse);
      expect(const PhotoSaveOutcome.cancelled().ok, isFalse);
    });
  });

  group('loadStudioImageBytes rejections', () {
    test('corrupt bytes → undecodable', () async {
      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.undecodable);
    });

    test('HEIC-looking bytes without adapter → heicConversionFailed', () async {
      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.heicConversionFailed);
    });

    test('adapter null on HEIC → heicConversionFailed', () async {
      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: (_) async => null,
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.heicConversionFailed);
    });

    test('oversized byte gate is separate from decode', () {
      expect(
        PhotoImportGate.rejectRawBytes(
          Uint8List(PhotoImportLimits.maxInputBytes + 1),
        ),
        PhotoImportRejection.tooLargeBytes,
      );
    });
  });
}
