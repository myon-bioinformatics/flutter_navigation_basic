import 'dart:typed_data';
import 'dart:ui' as ui;

/// Copies the exact byte range described by [bytes], respecting a non-zero
/// [ByteData.offsetInBytes] (unlike bare `buffer.asUint8List()`).
Uint8List uint8ListFromByteData(ByteData bytes) {
  return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

/// Encodes a captured [ui.Image] as PNG bytes.
///
/// Disposes [image] after encoding (including when encoding throws) so callers
/// do not need a separate dispose.
Future<Uint8List> encodeStudioPng(ui.Image image) async {
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Failed to encode studio PNG.');
    }
    return uint8ListFromByteData(bytes);
  } finally {
    image.dispose();
  }
}
