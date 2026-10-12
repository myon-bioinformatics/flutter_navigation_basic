import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/clipboard/base64_image_bridge.dart';

// Inputs mirror Ironmate tests/fixtures/base64_bridge_cases.json.
final _png = Uint8List.fromList(
  [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFB, 0xFF, 0x3E],
);
final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
final _webp = Uint8List.fromList(
  [...'RIFF'.codeUnits, 4, 0, 0, 0, ...'WEBP'.codeUnits],
);
final _gif = Uint8List.fromList('GIF89a\x01\x00\x01\x00'.codeUnits);

void main() {
  final b64 = base64Encode(_png); // contains '+', '/' and '=' padding

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

  group('bug 1: declared type must match the bytes', () {
    test('data URL says JPEG but bytes are PNG', () {
      expect(
        () => Base64ImageBridge.decodeText('data:image/jpeg;base64,$b64'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('image/png'))),
      );
    });
    test('raw Base64 GIF and other non-images are rejected', () {
      expect(() => Base64ImageBridge.decodeText(base64Encode(_gif)), throwsFormatException);
      expect(
        () => Base64ImageBridge.decodeText(base64Encode([1, 2, 3, 4])),
        throwsFormatException,
      );
    });
  });

  group('bug 2: data URL syntax', () {
    test('uppercase scheme, BOM and ;key=value parameters', () {
      for (final text in [
        'DATA:IMAGE/PNG;BASE64,$b64',
        '\uFEFF$b64',
        '\uFEFFdata:image/png;base64,$b64',
        'data:image/png;charset=utf-8;base64,$b64',
        'data:image/png;name=dot.png;base64,$b64',
      ]) {
        expect(Base64ImageBridge.decodeText(text).bytes, _png, reason: text);
      }
    });
    test('non-base64 data URL and quoted parameters fail with a clear message', () {
      for (final text in ['data:image/png,$b64', 'data:image/png;name="a b";base64,$b64']) {
        expect(
          () => Base64ImageBridge.decodeText(text),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('base64-encoded'))),
        );
      }
    });
  });

  group('bug 3/4: Base64 detection and strictness', () {
    final long = base64Encode(Uint8List.fromList([..._png, ...List.filled(200, 7)]));
    test('line-wrapped Base64 (CRLF at 76 columns, spaces, tabs) is detected and decoded', () {
      final wrapped = [for (var i = 0; i < long.length; i += 76) long.substring(i, i + 76 > long.length ? long.length : i + 76)]
          .join('\r\n');
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

  group('bug 7: one limit in bytes, chars derived', () {
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
