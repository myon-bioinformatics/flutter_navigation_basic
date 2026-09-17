import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_application_1/features/photo_studio/data/image_format_sniff.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_import_limits.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_import_status.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_image_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Probes [loadStudioImageBytes] against synthetic import-compat fixtures.
///
/// Records outcomes for the `flutter_test_ci` environment only. Browser /
/// iOS Safari / native picker cells stay `not_verified` unless a separate
/// environment fills them — never treat CI success as iOS Safari proof.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtureDir = Directory('test/fixtures/photo_studio/import_compat');
  final manifestFile = File('${fixtureDir.path}/manifest.json');

  Uint8List loadFixture(String name) =>
      File('${fixtureDir.path}/$name').readAsBytesSync();

  Future<String> probeDirect(Uint8List bytes) async {
    PhotoImportRejection? rejection;
    final loaded = await loadStudioImageBytes(
      bytes,
      onRejected: (r) => rejection = r,
    );
    if (loaded != null) return 'supported';
    return switch (rejection) {
      null => 'unsupported_by_runtime',
      PhotoImportRejection.empty => 'rejected:empty',
      PhotoImportRejection.tooLargeBytes => 'rejected:tooLargeBytes',
      PhotoImportRejection.tooManyPixels => 'rejected:tooManyPixels',
      PhotoImportRejection.heicConversionFailed =>
        'rejected:heicConversionFailed',
      PhotoImportRejection.undecodable => 'rejected:undecodable',
    };
  }

  test('manifest fixtures exist and sniff matches declared format', () {
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final cases = (manifest['cases'] as List).cast<Map<String, dynamic>>();
    expect(cases, isNotEmpty);
    for (final c in cases) {
      final fixture = c['fixture'] as String?;
      if (fixture == null) continue;
      final bytes = loadFixture(fixture);
      final sniff = sniffImageFormat(bytes);
      final format = c['format'] as String;
      if (format == 'empty') {
        expect(sniff.kind, ImageFormatKind.empty);
      } else if (format == 'heic') {
        expect(sniff.kind, ImageFormatKind.heic);
      } else if (format == 'avif') {
        expect(sniff.kind, ImageFormatKind.avif);
      } else if (format == 'png') {
        // truncated PNG may still sniff as png from signature
        expect(sniff.kind, ImageFormatKind.png);
      } else if (format == 'jpeg') {
        expect(sniff.kind, ImageFormatKind.jpeg);
      } else if (format == 'webp') {
        expect(sniff.kind, ImageFormatKind.webp);
      } else if (format == 'gif') {
        expect(sniff.kind, ImageFormatKind.gif);
      }
    }
  });

  test('direct Flutter codec: PNG / JPEG baseline supported', () async {
    expect(await probeDirect(loadFixture('png_opaque_2x2.png')), 'supported');
    expect(await probeDirect(loadFixture('png_alpha_2x2.png')), 'supported');
    expect(await probeDirect(loadFixture('jpeg_baseline_1x1.jpg')), 'supported');
    for (var o = 1; o <= 8; o++) {
      expect(
        await probeDirect(loadFixture('jpeg_exif_orientation_$o.jpg')),
        'supported',
        reason: 'orientation $o',
      );
    }
  });

  test('direct Flutter codec: HEIC ftyp brands → heicConversionFailed', () async {
    for (final brand in ['heic', 'heif', 'mif1', 'msf1', 'heix']) {
      final outcome =
          await probeDirect(loadFixture('heic_ftyp_$brand.heic'));
      expect(outcome, 'rejected:heicConversionFailed', reason: brand);
      expect(
        PhotoImportStatus.fromRejection(
          PhotoImportRejection.heicConversionFailed,
        ),
        PhotoImportFailureReason.heicUnsupported,
      );
    }
  });

  test('direct Flutter codec: empty / truncated / pixel claim / byte oversize',
      () async {
    expect(await probeDirect(Uint8List(0)), 'rejected:empty');
    expect(
      await probeDirect(loadFixture('png_truncated.png')),
      anyOf('rejected:undecodable', 'unsupported_by_runtime'),
    );
    expect(
      await probeDirect(loadFixture('png_claim_10000x10000.png')),
      'rejected:tooManyPixels',
    );
    final oversize = Uint8List(PhotoImportLimits.maxInputBytes + 1);
    PhotoImportRejection? rejection;
    final loaded = await loadStudioImageBytes(
      oversize,
      onRejected: (r) => rejection = r,
    );
    // Loader checks empty first; byte gate is on the page via rejectRawBytes.
    // Document both: gate rejects bytes; loader may treat as undecodable/empty.
    expect(loaded, isNull);
    expect(
      PhotoImportGate.rejectRawBytes(oversize),
      PhotoImportRejection.tooLargeBytes,
    );
    expect(
      rejection,
      anyOf(
        isNull,
        PhotoImportRejection.undecodable,
        PhotoImportRejection.empty,
      ),
    );
  });

  test('AVIF / GIF / WebP / progressive JPEG: record without claiming Safari',
      () async {
    final progressive =
        await probeDirect(loadFixture('jpeg_progressive_1x1.jpg'));
    expect(
      progressive,
      anyOf('supported', 'rejected:undecodable', 'unsupported_by_runtime'),
    );

    final gif = await probeDirect(loadFixture('gif_still_1x1.gif'));
    expect(
      gif,
      anyOf('supported', 'rejected:undecodable', 'unsupported_by_runtime'),
    );

    for (final name in [
      'webp_lossy_2x2.webp',
      'webp_lossless_1x1.webp',
      'webp_alpha_1x1.webp',
    ]) {
      final out = await probeDirect(loadFixture(name));
      expect(
        out,
        anyOf('supported', 'rejected:undecodable', 'unsupported_by_runtime'),
        reason: name,
      );
    }

    final avif = await probeDirect(loadFixture('avif_ftyp_only.avif'));
    expect(
      avif,
      anyOf('rejected:undecodable', 'unsupported_by_runtime'),
    );
  });

  test('native adapter path: HEIC stays heic when adapter returns null', () async {
    PhotoImportRejection? rejection;
    final loaded = await loadStudioImageBytes(
      loadFixture('heic_ftyp_heic.heic'),
      nativeDecodeAdapter: (_) async => null,
      onRejected: (r) => rejection = r,
    );
    expect(loaded, isNull);
    expect(rejection, PhotoImportRejection.heicConversionFailed);
  });

  test('native adapter path: successful PNG normalize accepts HEIC input',
      () async {
    final png = loadFixture('png_opaque_2x2.png');
    final loaded = await loadStudioImageBytes(
      loadFixture('heic_ftyp_heic.heic'),
      nativeDecodeAdapter: (_) async => png,
    );
    expect(loaded, png);
  });

  test('failure reasons map to distinct safe l10n keys (no secrets)', () {
    expect(
      const PhotoImportStatus.failure(
        reason: PhotoImportFailureReason.heicUnsupported,
      ).messageKey,
      'photoStudio.imageHeicUnsupported',
    );
    expect(
      const PhotoImportStatus.failure(
        reason: PhotoImportFailureReason.tooManyPixels,
      ).messageKey,
      'photoStudio.imageTooManyPixels',
    );
    expect(
      const PhotoImportStatus.failure(
        reason: PhotoImportFailureReason.tooLargeBytes,
      ).messageKey,
      'photoStudio.imageTooLarge',
    );
    expect(
      const PhotoImportStatus.failure(
        reason: PhotoImportFailureReason.decodeFailed,
      ).messageKey,
      'photoStudio.imageError',
    );
  });
}
