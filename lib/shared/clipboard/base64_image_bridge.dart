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
  static const Set<String> supportedRasterMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/webp',
  };

  static ({int width, int height}) targetDimensions({
    required int width,
    required int height,
    double scale = defaultScale,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be positive');
    }
    if (scale <= 0 || scale > 1) {
      throw ArgumentError.value(scale, 'scale', 'must be > 0 and <= 1');
    }
    return (
      width: (width * scale).round().clamp(1, width).toInt(),
      height: (height * scale).round().clamp(1, height).toInt(),
    );
  }

  static Future<Base64ImagePayload> downscaleToPng(
    Uint8List source, {
    double scale = defaultScale,
    int maxLongEdge = 4096,
  }) async {
    if (source.isEmpty) {
      throw const FormatException('Image bytes are empty.');
    }
    if (maxLongEdge < 1) {
      throw ArgumentError.value(maxLongEdge, 'maxLongEdge', 'must be >= 1');
    }

    final sourceCodec = await ui.instantiateImageCodec(source);
    final sourceFrame = await sourceCodec.getNextFrame();
    final sourceImage = sourceFrame.image;
    final sourceWidth = sourceImage.width;
    final sourceHeight = sourceImage.height;
    sourceImage.dispose();
    sourceCodec.dispose();

    var target = targetDimensions(
      width: sourceWidth,
      height: sourceHeight,
      scale: scale,
    );
    final longEdge = target.width > target.height ? target.width : target.height;
    if (longEdge > maxLongEdge) {
      final fit = maxLongEdge / longEdge;
      target = (
        width: (target.width * fit).round().clamp(1, sourceWidth).toInt(),
        height: (target.height * fit).round().clamp(1, sourceHeight).toInt(),
      );
    }
    final scaledCodec = await ui.instantiateImageCodec(
      source,
      targetWidth: target.width,
      targetHeight: target.height,
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
      bytes: pngData.buffer.asUint8List(
        pngData.offsetInBytes,
        pngData.lengthInBytes,
      ),
      mimeType: 'image/png',
    );
  }

  static Base64ImagePayload decodeText(String input) {
    final text = input.trim();
    if (text.isEmpty) throw const FormatException('Base64 input is empty.');

    final dataUrl = RegExp(
      r'^data:([^;,]+);base64,(.*)$',
      dotAll: true,
    ).firstMatch(text);
    final mimeType = (dataUrl?.group(1) ?? 'image/png').toLowerCase();
    final encoded = (dataUrl?.group(2) ?? text).replaceAll(RegExp(r'\s+'), '');
    if (!supportedRasterMimeTypes.contains(mimeType)) {
      throw FormatException(
        'Unsupported image MIME type: $mimeType. '
        'Use PNG, JPEG, or WebP.',
      );
    }
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty) {
      throw const FormatException('Decoded image bytes are empty.');
    }
    return Base64ImagePayload(bytes: bytes, mimeType: mimeType);
  }
}
