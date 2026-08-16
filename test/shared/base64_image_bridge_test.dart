import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/clipboard/base64_image_bridge.dart';

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

  test('rejects unsupported image MIME types', () {
    final encoded = base64Encode(<int>[1, 2, 3, 4]);
    expect(
      () => Base64ImageBridge.decodeText('data:image/svg+xml;base64,$encoded'),
      throwsFormatException,
    );
  });

  testWidgets('downscales dimensions to two thirds and re-encodes PNG', (tester) async {
    final source = await _makePng(width: 6, height: 3);
    final result = await Base64ImageBridge.downscaleToPng(source);

    expect(result.mimeType, 'image/png');
    expect(result.bytes, isNotEmpty);
    expect(result.dataUrl, startsWith('data:image/png;base64,'));

    final codec = await ui.instantiateImageCodec(result.bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 4);
    expect(frame.image.height, 2);
    frame.image.dispose();
    codec.dispose();
  });
}

Future<Uint8List> _makePng({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) throw StateError('Could not create PNG fixture.');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
