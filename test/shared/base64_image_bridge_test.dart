import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/clipboard/base64_image_bridge.dart';

void main() {
  test('decodes image data URLs and raw Base64', () {
    final bytes = <int>[1, 2, 3, 4];
    final encoded = base64Encode(bytes);

    final dataUrl = Base64ImageBridge.decodeText('data:image/png;base64,$encoded');
    expect(dataUrl.mimeType, 'image/png');
    expect(dataUrl.bytes, bytes);

    final raw = Base64ImageBridge.decodeText(encoded);
    expect(raw.mimeType, 'image/png');
    expect(raw.bytes, bytes);
  });

  test('rejects unsupported image MIME types', () {
    final encoded = base64Encode(<int>[1, 2, 3, 4]);
    expect(
      () => Base64ImageBridge.decodeText('data:image/svg+xml;base64,$encoded'),
      throwsFormatException,
    );
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
