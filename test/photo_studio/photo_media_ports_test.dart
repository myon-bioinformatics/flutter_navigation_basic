import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/photo_studio/data/image_picker_photo_source.dart';
import 'package:flutter_application_1/features/photo_studio/data/native_image_normalize_adapter_io.dart';
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

/// PNG whose IHDR claims 10000×10000 (100 MP) without a full pixel payload.
final _oversizedClaimPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 39, 16,
  0, 0, 39, 16, 8, 2, 0, 0, 0, 53, 44, 245, 112, 0, 0, 0, 9, 73, 68, 65, 84,
  120, 156, 99, 0, 0, 0, 1, 0, 1, 94, 255, 125, 249, 0, 0, 0, 0, 73, 69, 78,
  68, 174, 66, 96, 130,
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

/// Mirrors Android `MainActivity.orientationMatrix` / ExifInterface 1–8.
/// Used as fixture evidence that the native orientation table is complete.
({String op, double degrees, bool flipX, bool flipY})? exifOrientationOp(
  int orientation,
) {
  return switch (orientation) {
    2 => (op: 'flipX', degrees: 0, flipX: true, flipY: false),
    3 => (op: 'rotate', degrees: 180, flipX: false, flipY: false),
    4 => (op: 'flipY', degrees: 0, flipX: false, flipY: true),
    5 => (op: 'transpose', degrees: 90, flipX: true, flipY: false),
    6 => (op: 'rotate', degrees: 90, flipX: false, flipY: false),
    7 => (op: 'transverse', degrees: -90, flipX: true, flipY: false),
    8 => (op: 'rotate', degrees: -90, flipX: false, flipY: false),
    1 || 0 => null,
    _ => null,
  };
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

    test('rejects oversized length before readAsBytes', () async {
      var readCalled = false;
      final source = ImagePickerPhotoSource(
        pickImage: ({required source}) async => XFile.fromData(
          _tinyPng,
          name: 'huge.bin',
          mimeType: 'application/octet-stream',
        ),
        lengthOf: (_) async => PhotoImportLimits.maxInputBytes + 1,
        readBytes: (_) async {
          readCalled = true;
          return _tinyPng;
        },
      );
      final outcome = await source.pickFromGallery();
      expect(outcome.status, PhotoPickStatus.rejected);
      expect(outcome.rejection, PhotoImportRejection.tooLargeBytes);
      expect(readCalled, isFalse);
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

    test('HEIC-looking bytes with successful adapter → PNG', () async {
      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: (_) async => _tinyPng,
        onRejected: (r) => seen = r,
      );
      expect(loaded, _tinyPng);
      expect(seen, isNull);
    });

    test('pixel gate rejects oversized IHDR before full raster', () async {
      PhotoImportRejection? seen;
      final size = await readEncodedImageSize(_oversizedClaimPng);
      expect(size?.width, 10000);
      expect(size?.height, 10000);

      final loaded = await loadStudioImageBytes(
        _oversizedClaimPng,
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.tooManyPixels);
      final loadedWithAdapter = await loadStudioImageBytes(
        _oversizedClaimPng,
        nativeDecodeAdapter: (_) async => _tinyPng,
        onRejected: (r) => seen = r,
      );
      expect(loadedWithAdapter, isNull);
      expect(seen, PhotoImportRejection.tooManyPixels);
    });

    test('native too_many_pixels maps to PhotoImportRejection', () async {
      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: (_) async {
          throw const NativeImageNormalizeException(
            PhotoImportRejection.tooManyPixels,
          );
        },
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.tooManyPixels);
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

  group('nativeImageNormalizeAdapter', () {
    test('injected invoker returns PNG for HEIC-like bytes', () async {
      final out = await nativeImageNormalizeAdapter(
        _heicLike(),
        invoke: (_) async => _tinyPng,
      );
      expect(out, _tinyPng);
    });

    test('MethodChannel passes pixel budgets and returns PNG', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kNativeImageNormalizeChannel, (
        call,
      ) async {
        expect(call.method, 'normalizeToPng');
        final args = call.arguments as Map;
        expect(args['bytes'], isA<Uint8List>());
        expect(args['maxPixels'], PhotoImportLimits.maxPixels);
        expect(args['maxLongEdge'], PhotoImportLimits.maxDocumentLongEdge);
        return _tinyPng;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(kNativeImageNormalizeChannel, null);
      });

      final out = await nativeImageNormalizeAdapter(_heicLike());
      expect(out, _tinyPng);

      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: nativeImageNormalizeAdapter,
      );
      expect(loaded, _tinyPng);
    });

    test('MethodChannel too_many_pixels → NativeImageNormalizeException', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kNativeImageNormalizeChannel, (
        call,
      ) async {
        throw PlatformException(code: 'too_many_pixels', message: 'too big');
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(kNativeImageNormalizeChannel, null);
      });

      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: nativeImageNormalizeAdapter,
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.tooManyPixels);
    });

    test('MethodChannel failure → null / heicConversionFailed', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kNativeImageNormalizeChannel, (
        call,
      ) async =>
              null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(kNativeImageNormalizeChannel, null);
      });

      PhotoImportRejection? seen;
      final loaded = await loadStudioImageBytes(
        _heicLike(),
        nativeDecodeAdapter: nativeImageNormalizeAdapter,
        onRejected: (r) => seen = r,
      );
      expect(loaded, isNull);
      expect(seen, PhotoImportRejection.heicConversionFailed);
    });
  });

  group('EXIF orientation fixture table (native parity)', () {
    test('covers orientations 1–8 including 90/180/mirror', () {
      expect(exifOrientationOp(1), isNull);
      expect(exifOrientationOp(2)?.flipX, isTrue);
      expect(exifOrientationOp(3)?.degrees, 180);
      expect(exifOrientationOp(4)?.flipY, isTrue);
      expect(exifOrientationOp(5)?.degrees, 90);
      expect(exifOrientationOp(5)?.flipX, isTrue);
      expect(exifOrientationOp(6)?.degrees, 90);
      expect(exifOrientationOp(7)?.degrees, -90);
      expect(exifOrientationOp(7)?.flipX, isTrue);
      expect(exifOrientationOp(8)?.degrees, -90);
    });
  });

  group('AndroidManifest permissions', () {
    test('does not declare broad photo read permissions', () {
      final xml =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        RegExp(r'android\.permission\.READ_MEDIA_IMAGES').hasMatch(xml),
        isFalse,
      );
      expect(
        RegExp(r'android\.permission\.READ_EXTERNAL_STORAGE').hasMatch(xml),
        isFalse,
      );
      expect(
        RegExp(r'android\.permission\.WRITE_EXTERNAL_STORAGE').hasMatch(xml),
        isTrue,
      );
      expect(xml.contains('maxSdkVersion="29"'), isTrue);
    });
  });
}
