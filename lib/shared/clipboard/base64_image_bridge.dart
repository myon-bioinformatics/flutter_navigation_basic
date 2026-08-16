import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

class Base64ImagePayload {
  const Base64ImagePayload({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

class Base64ImageBridge {
  const Base64ImageBridge._();

  static const double defaultScale = 2 / 3;

  static Future<Base64ImagePayload> downscaleToPng(
    Uint8List source, {
    double scale = defaultScale,
  }) async {
    if (source.isEmpty) {
      throw const FormatException('Image bytes are empty.');
    }
    if (scale <= 0 || scale > 1) {
      throw ArgumentError.value(scale, 'scale', 'must be > 0 and <= 1');
    }

    final sourceCodec = await ui.instantiateImageCodec(source);
    final sourceFrame = await sourceCodec.getNextFrame();
    final sourceImage = sourceFrame.image;
    final targetWidth = (sourceImage.width * scale).round().clamp(1, sourceImage.width);
    final targetHeight = (sourceImage.height * scale).round().clamp(1, sourceImage.height);
    sourceImage.dispose();
    sourceCodec.dispose();

    final scaledCodec = await ui.instantiateImageCodec(
      source,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: false,
    );
    final scaledFrame = await scaledCodec.getNextFrame();
    final scaledImage = scaledFrame.image;
    final pngData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
    scaledImage.dispose();
    scaledCodec.dispose();

    if (pngData == null) {
      throw StateError('Flutter could not encode the resized image as PNG.');
    }
    return Base64ImagePayload(
      bytes: pngData.buffer.asUint8List(pngData.offsetInBytes, pngData.lengthInBytes),
      mimeType: 'image/png',
    );
  }

  static Base64ImagePayload decodeText(String input) {
    final text = input.trim();
    if (text.isEmpty) throw const FormatException('Base64 input is empty.');

    final dataUrl = RegExp(r'^data:([^;,]+);base64,(.*)$', dotAll: true).firstMatch(text);
    final mimeType = dataUrl?.group(1) ?? 'image/png';
    final encoded = (dataUrl?.group(2) ?? text).replaceAll(RegExp(r'\s+'), '');
    if (!mimeType.startsWith('image/')) {
      throw FormatException('Expected image/* data URL, got $mimeType.');
    }
    return Base64ImagePayload(bytes: base64Decode(encoded), mimeType: mimeType);
  }
}
