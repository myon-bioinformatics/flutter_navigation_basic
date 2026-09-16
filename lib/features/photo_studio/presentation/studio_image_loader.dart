import 'dart:typed_data';
import 'dart:ui' as ui;

import '../data/photo_media_ports.dart';

/// Decodes [bytes] with Flutter's codec. Returns null when empty/corrupt.
Future<({Uint8List bytes, int width, int height})?> decodeRasterImageBytes(
  Uint8List bytes,
) async {
  if (bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();
    return (bytes: bytes, width: width, height: height);
  } catch (_) {
    return null;
  }
}

/// Optional platform/browser adapter that converts unsupported bytes to PNG.
typedef StudioImageDecodeAdapter = Future<Uint8List?> Function(Uint8List bytes);

/// Validates image bytes via Flutter decode, then an optional native adapter.
///
/// Returns PNG-ready bytes only after a successful decode path and pixel-budget
/// check. Empty, truncated, oversized, or unsupported payloads yield null (or
/// a [PhotoImportRejection] via [rejectionOut]) so callers can show an error
/// instead of treating a blank canvas as success.
Future<Uint8List?> loadStudioImageBytes(
  Uint8List rawBytes, {
  StudioImageDecodeAdapter? nativeDecodeAdapter,
  void Function(PhotoImportRejection rejection)? onRejected,
}) async {
  if (rawBytes.isEmpty) {
    onRejected?.call(PhotoImportRejection.empty);
    return null;
  }

  Future<Uint8List?> accept(
    ({Uint8List bytes, int width, int height}) decoded,
  ) async {
    final sizeReject = PhotoImportGate.rejectDecodedSize(
      width: decoded.width,
      height: decoded.height,
    );
    if (sizeReject != null) {
      onRejected?.call(sizeReject);
      return null;
    }
    return decoded.bytes;
  }

  final direct = await decodeRasterImageBytes(rawBytes);
  if (direct != null) return accept(direct);

  final adapter = nativeDecodeAdapter;
  if (adapter == null) {
    onRejected?.call(
      PhotoImportGate.looksLikeHeic(rawBytes)
          ? PhotoImportRejection.heicConversionFailed
          : PhotoImportRejection.undecodable,
    );
    return null;
  }

  final adapted = await adapter(rawBytes);
  if (adapted == null || adapted.isEmpty) {
    onRejected?.call(
      PhotoImportGate.looksLikeHeic(rawBytes)
          ? PhotoImportRejection.heicConversionFailed
          : PhotoImportRejection.undecodable,
    );
    return null;
  }

  // Adapter output must still decode as a real raster image.
  final adaptedDecoded = await decodeRasterImageBytes(adapted);
  if (adaptedDecoded == null) {
    onRejected?.call(PhotoImportRejection.undecodable);
    return null;
  }
  return accept(adaptedDecoded);
}
