import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodes [bytes] with Flutter's codec. Returns null when empty/corrupt.
Future<Uint8List?> decodeRasterImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
    return bytes;
  } catch (_) {
    return null;
  }
}

/// Optional platform/browser adapter that converts unsupported bytes to PNG.
typedef StudioImageDecodeAdapter = Future<Uint8List?> Function(Uint8List bytes);

/// Validates image bytes via Flutter decode, then an optional native adapter.
///
/// Returns PNG-ready bytes only after a successful decode path. Empty,
/// truncated, or unsupported payloads yield null so callers can show an error
/// instead of treating a blank canvas as success.
Future<Uint8List?> loadStudioImageBytes(
  Uint8List rawBytes, {
  StudioImageDecodeAdapter? nativeDecodeAdapter,
}) async {
  if (rawBytes.isEmpty) return null;

  final direct = await decodeRasterImageBytes(rawBytes);
  if (direct != null) return direct;

  final adapter = nativeDecodeAdapter;
  if (adapter == null) return null;

  final adapted = await adapter(rawBytes);
  if (adapted == null || adapted.isEmpty) return null;

  // Adapter output must still decode as a real raster image.
  return decodeRasterImageBytes(adapted);
}
