import 'dart:typed_data';
import 'dart:ui' as ui;

/// Encodes a captured [ui.Image] as PNG bytes.
///
/// Disposes [image] after encoding so callers do not need a separate dispose.
Future<Uint8List> encodeStudioPng(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) {
    throw StateError('Failed to encode studio PNG.');
  }
  return bytes.buffer.asUint8List();
}
