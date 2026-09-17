import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_application_1/features/photo_studio/data/image_format_sniff.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_import_limits.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_import_status.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_image_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Strict evidence checks for Photo Studio import compatibility.
///
/// Outcomes must match `evidence/flutter_test_ci.json` exactly for
/// `loader_direct_flutter_codec`. Other environments stay `not_verified`
/// and must not be inferred from this suite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtureDir = Directory('test/fixtures/photo_studio/import_compat');
  final casesFile = File('${fixtureDir.path}/cases.json');
  final evidenceFile =
      File('${fixtureDir.path}/evidence/flutter_test_ci.json');

  Map<String, dynamic> loadJson(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  Uint8List loadFixture(String name) =>
      File('${fixtureDir.path}/$name').readAsBytesSync();

  Future<String> probeDirect(
    Uint8List bytes, {
    StudioImageDecodeAdapter? adapter,
  }) async {
    PhotoImportRejection? rejection;
    final loaded = await loadStudioImageBytes(
      bytes,
      nativeDecodeAdapter: adapter,
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

  Future<({int width, int height, List<int> tl})> decodeTl(
    Uint8List bytes,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = data!.buffer.asUint8List();
    final tl = [rgba[0], rgba[1], rgba[2], rgba[3]];
    final size = (width: image.width, height: image.height, tl: tl);
    image.dispose();
    codec.dispose();
    return size;
  }

  String dominant(List<int> px) {
    final r = px[0], g = px[1], b = px[2];
    if (r > 200 && g < 80 && b < 80) return 'red';
    if (g > 200 && r < 80 && b < 80) return 'lime';
    if (b > 200 && r < 80 && g < 80) return 'blue';
    if (r > 200 && g > 200 && b < 80) return 'yellow';
    return 'other';
  }

  test('cases.json fixtures exist; evidence covers every case id', () {
    final casesDoc = loadJson(casesFile);
    final evidence = loadJson(evidenceFile);
    final caseIds = (casesDoc['cases'] as List)
        .cast<Map<String, dynamic>>()
        .map((c) => c['id'] as String)
        .toSet();
    final outcomeIds =
        (evidence['outcomes'] as Map).keys.map((k) => k.toString()).toSet();
    expect(outcomeIds, caseIds);

    for (final c in (casesDoc['cases'] as List).cast<Map<String, dynamic>>()) {
      final fixture = c['fixture'] as String?;
      if (fixture == null) continue;
      expect(
        File('${fixtureDir.path}/$fixture').existsSync(),
        isTrue,
        reason: fixture,
      );
    }
  });

  test('loader_direct outcomes match evidence exactly', () async {
    final casesDoc = loadJson(casesFile);
    final evidence = loadJson(evidenceFile);
    final outcomes = evidence['outcomes'] as Map<String, dynamic>;

    for (final c in (casesDoc['cases'] as List).cast<Map<String, dynamic>>()) {
      final id = c['id'] as String;
      final expected = (outcomes[id] as Map)['loader_direct_flutter_codec'];
      expect(expected, isA<String>(), reason: id);

      if (id == 'oversize_bytes_runtime') {
        final oversize = Uint8List(PhotoImportLimits.maxInputBytes + 1);
        expect(
          PhotoImportGate.rejectRawBytes(oversize),
          PhotoImportRejection.tooLargeBytes,
        );
        expect(expected, 'rejected:tooLargeBytes');
        continue;
      }

      final fixture = c['fixture'] as String;
      final actual = await probeDirect(loadFixture(fixture));
      expect(actual, expected, reason: id);
    }
  });

  test('HEIC synthetic vs ftyp-only kinds are separated in cases.json', () {
    final casesDoc = loadJson(casesFile);
    final byId = {
      for (final c in (casesDoc['cases'] as List).cast<Map<String, dynamic>>())
        c['id'] as String: c,
    };
    expect(byId['heic_ftyp_heic']!['kind'], 'container_sniff');
    expect(byId['heic_synthetic_markers_64x32']!['kind'], 'raster');
    expect(
      sniffImageFormat(loadFixture('heic_synthetic_markers_64x32.heic')).kind,
      ImageFormatKind.heic,
    );
  });

  test('native adapter null on synthetic HEIC matches evidence', () async {
    final evidence = loadJson(evidenceFile);
    final expected = (evidence['outcomes']
            as Map)['heic_synthetic_markers_64x32']['loader_native_normalize_adapter'];
    final actual = await probeDirect(
      loadFixture('heic_synthetic_markers_64x32.heic'),
      adapter: (_) async => null,
    );
    expect(actual, expected);
    expect(
      PhotoImportStatus.fromRejection(
        PhotoImportRejection.heicConversionFailed,
      ),
      PhotoImportFailureReason.heicUnsupported,
    );
  });

  test('EXIF orientation 1–8 visual expectations match evidence', () async {
    final evidence = loadJson(evidenceFile);
    final visual =
        evidence['exifOrientationVisual'] as Map<String, dynamic>;
    final expectations = visual['expectations'] as Map<String, dynamic>;
    expect(visual['status'], 'supported');

    for (final entry in expectations.entries) {
      final o = entry.key;
      final exp = entry.value as Map<String, dynamic>;
      final bytes =
          loadFixture('jpeg_exif_orientation_${o}_markers_64x32.jpg');
      expect(sniffImageFormat(bytes).jpegExifOrientation, int.parse(o));
      // Decode applies EXIF (Flutter codec), then sample TL.
      final raster = await decodeTl(bytes);
      expect(raster.width, exp['width'], reason: 'O$o width');
      expect(raster.height, exp['height'], reason: 'O$o height');
      expect(dominant(raster.tl), exp['tlDominant'], reason: 'O$o TL');
    }
  });

  test('WebP alpha fixture has transparent TL pixel', () async {
    final evidence = loadJson(evidenceFile);
    final visual = evidence['webpAlphaVisual'] as Map<String, dynamic>;
    expect(visual['status'], 'supported');
    final raster = await decodeTl(loadFixture(visual['fixture'] as String));
    expect(raster.tl[3], greaterThanOrEqualTo(visual['expectTlAlphaMin'] as int));
    expect(raster.tl[3], lessThanOrEqualTo(visual['expectTlAlphaMax'] as int));
    expect(raster.tl[3], lessThan(255));
  });

  test('ios_safari / web_chrome evidence files stay empty (not_verified)', () {
    for (final name in ['ios_safari_iphone', 'web_chrome_ci']) {
      final doc = loadJson(
        File('${fixtureDir.path}/evidence/$name.json'),
      );
      expect(doc['outcomes'], isEmpty, reason: name);
    }
  });
}
