import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_navigation_basic/shared/clipboard/base64_image_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('downscales and re-encodes a PNG without a plugin', (tester) async {
    const transparentPixel =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final result = await Base64ImageBridge.downscaleToPng(
      base64Decode(transparentPixel),
    );

    expect(result.mimeType, 'image/png');
    expect(result.bytes, isNotEmpty);
    expect(result.dataUrl, startsWith('data:image/png;base64,'));
  });
}
