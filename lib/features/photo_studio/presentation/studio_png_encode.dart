import 'dart:typed_data';
import 'dart:ui' as ui;

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
    return bytes.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
