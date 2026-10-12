import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/clipboard/base64_image_bridge.dart';

import 'base64_bridge_fixtures.dart';

final _png = Uint8List.fromList(
  [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFB, 0xFF, 0x3E],
);
final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
final _webp = Uint8List.fromList(
  [...'RIFF'.codeUnits, 4, 0, 0, 0, ...'WEBP'.codeUnits],
);
/// Mimics pre-fix [Base64ImageBridge.decodeText] (no magic-byte verification).
Base64ImagePayload legacyDecodeWithoutMagicBytes(String input) {
  final text = input.trim();
  if (text.isEmpty) throw const FormatException('Base64 input is empty.');

  final dataUrl = RegExp(
    r'^data:([^;,]+);base64,(.*)$',
    dotAll: true,
  ).firstMatch(text);
  final mimeType = (dataUrl?.group(1) ?? 'image/png').toLowerCase();
  final encoded = (dataUrl?.group(2) ?? text).replaceAll(RegExp(r'\s+'), '');
  if (!Base64ImageBridge.supportedRasterMimeTypes.contains(mimeType)) {
    throw FormatException('Unsupported image MIME type: $mimeType.');
  }
  final bytes = base64Decode(encoded);
  if (bytes.isEmpty) {
    throw const FormatException('Decoded image bytes are empty.');
  }
  return Base64ImagePayload(bytes: bytes, mimeType: mimeType);
}

void main() {
  final b64 = base64Encode(_png);

  group('Ironmate base64_bridge_cases.json contract', () {
    test('vendored fixture hash matches provenance', () {
      Base64BridgeFixtures.assertProvenanceHashMatches();
    });

    test('expectation mapping covers every case id exactly once', () {
      final cases = Base64BridgeFixtures.loadCases();
      final expectations = Base64BridgeFixtures.loadExpectationsById();
      final ids = cases.map((c) => c['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
      expect(expectations.keys.toSet(), ids.toSet());
    });

    final ironmateCases = Base64BridgeFixtures.loadCases();
    for (final caseData in ironmateCases) {
      final id = caseData['id'] as String;
      test('case $id', () {
        final expectation = Base64BridgeFixtures.loadExpectationsById()[id]!;
        final text = caseData['text'] as String;
        final accept = expectation['accept'] == true;
        if (accept) {
          final payload = Base64ImageBridge.decodeText(text);
          expect(
            Base64BridgeFixtures.detectedFormatFromPayload(payload),
            expectation['detectedFormat'],
          );
        } else {
          expect(
            () => Base64ImageBridge.decodeText(text),
            throwsFormatException,
            reason: id,
          );
        }
      });
    }

    test('fixture maxInputBytes limit rejects oversize decoded payloads', () {
      final limits = Base64BridgeFixtures.loadCasesDocument()['limits'] as Map;
      final maxBytes = limits['maxInputBytes'] as int;
      final over = base64Encode(Uint8List.fromList([..._png, ...List.filled(maxBytes, 0)]));
      expect(
        () => Base64ImageBridge.decodeText(over, maxBytes: maxBytes),
        throwsFormatException,
      );
    });
  });

  test('adversarial: legacy decoder without magic-byte check fails the contract', () {
    final cases = Base64BridgeFixtures.loadCases();
    final expectations = Base64BridgeFixtures.loadExpectationsById();
    final wronglyAccepted = <String>[];
    for (final caseData in cases) {
      final id = caseData['id'] as String;
      if (expectations[id]!['accept'] == true) continue;
      try {
        legacyDecodeWithoutMagicBytes(caseData['text'] as String);
        wronglyAccepted.add(id);
      } on FormatException {
        // expected for many reject cases
      }
    }
    expect(
      wronglyAccepted,
      isNotEmpty,
      reason: 'legacy path must accept at least one case the contract rejects',
    );
    expect(
      wronglyAccepted,
      containsAll(['data_mismatch_jpeg_label', 'data_mismatch_png_label', 'raw_gif']),
    );
    for (final id in wronglyAccepted) {
      expect(
        () => Base64ImageBridge.decodeText(
          cases.firstWhere((c) => c['id'] == id)['text'] as String,
        ),
        throwsFormatException,
        reason: 'strict decoder must reject $id',
      );
    }
  });

  test('decodes image data URLs and raw Base64', () {
    final dataUrl = Base64ImageBridge.decodeText('data:image/png;base64,$b64');
    expect(dataUrl.mimeType, 'image/png');
    expect(dataUrl.bytes, _png);

    final raw = Base64ImageBridge.decodeText(b64);
    expect(raw.mimeType, 'image/png');
    expect(raw.bytes, _png);
  });

  test('raw Base64 takes its MIME type from the bytes', () {
    expect(Base64ImageBridge.decodeText(base64Encode(_jpeg)).mimeType, 'image/jpeg');
    expect(Base64ImageBridge.decodeText(base64Encode(_webp)).mimeType, 'image/webp');
    expect(
      Base64ImageBridge.decodeText('data:image/jpg;base64,${base64Encode(_jpeg)}').mimeType,
      'image/jpeg',
    );
  });

  test('rejects unsupported image MIME types', () {
    expect(
      () => Base64ImageBridge.decodeText('data:image/svg+xml;base64,$b64'),
      throwsFormatException,
    );
  });

  group('looksLikeImageText and strict Base64', () {
    final long = base64Encode(Uint8List.fromList([..._png, ...List.filled(200, 7)]));
    test('line-wrapped Base64 (CRLF at 76 columns, spaces, tabs) is detected and decoded', () {
      final wrapped = [
        for (var i = 0; i < long.length; i += 76)
          long.substring(i, i + 76 > long.length ? long.length : i + 76),
      ].join('\r\n');
      expect(Base64ImageBridge.looksLikeImageText(wrapped), isTrue);
      expect(Base64ImageBridge.decodeText(wrapped).bytes.length, _png.length + 200);
      final spaced = long.replaceAllMapped(RegExp(r'.{20}'), (m) => '${m[0]} \t');
      expect(Base64ImageBridge.looksLikeImageText(spaced), isTrue);
      expect(Base64ImageBridge.looksLikeImageText('DATA:image/png;base64,x'), isTrue);
      expect(Base64ImageBridge.looksLikeImageText('hello world'), isFalse);
    });
    test('URL-safe, %3D and unpadded input are rejected', () {
      for (final text in [
        b64.replaceAll('+', '-').replaceAll('/', '_'),
        b64.replaceAll('=', '%3D'),
        b64.replaceAll('=', ''),
        '$b64==',
      ]) {
        expect(() => Base64ImageBridge.decodeText(text), throwsFormatException, reason: text);
      }
    });
  });

  group('maxBytes limit', () {
    test('maxBase64Chars matches the Base64 length', () {
      for (var n = 0; n < 20; n++) {
        expect(Base64ImageBridge.maxBase64Chars(n), base64Encode(List.filled(n, 0)).length);
      }
    });
    test('decodeText maxBytes applies to raw and data URL alike', () {
      final exact = base64Encode(Uint8List.fromList([..._png, ...List.filled(89, 0)]));
      final over = base64Encode(Uint8List.fromList([..._png, ...List.filled(90, 0)]));
      for (final prefix in ['', 'data:image/png;base64,']) {
        expect(Base64ImageBridge.decodeText('$prefix$exact', maxBytes: 100).bytes.length, 100);
        expect(() => Base64ImageBridge.decodeText('$prefix$over', maxBytes: 100), throwsFormatException);
      }
    });
  });

  test('calculates two-thirds target dimensions without upscaling', () {
    final target = Base64ImageBridge.targetDimensions(width: 6, height: 3);
    expect(target.width, 4);
    expect(target.height, 2);

    final onePixel = Base64ImageBridge.targetDimensions(width: 1, height: 1);
    expect(onePixel.width, 1);
    expect(onePixel.height, 1);
  });

  test('rejects invalid resize inputs', () {
    expect(
      () => Base64ImageBridge.targetDimensions(width: 0, height: 3),
      throwsArgumentError,
    );
    expect(
      () => Base64ImageBridge.targetDimensions(width: 6, height: 3, scale: 0),
      throwsArgumentError,
    );
  });
}
