import 'dart:typed_data';
import 'dart:ui' as ui;

import '../data/photo_media_ports.dart';

/// Reads encoded image width/height without allocating a full-size raster.
///
/// Uses [ui.ImmutableBuffer] + [ui.ImageDescriptor.encoded] so pixel budgets
/// can be enforced before [ui.Codec.getNextFrame] materializes bitmaps.
Future<({int width, int height})?> readEncodedImageSize(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    if (width <= 0 || height <= 0) return null;
    return (width: width, height: height);
  } catch (_) {
    return null;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// Probes encoded dimensions only (no full-frame raster). Prefer this over
/// legacy callers that used to decode a full bitmap just to read size.
Future<({Uint8List bytes, int width, int height})?> decodeRasterImageBytes(
  Uint8List bytes,
) async {
  final size = await readEncodedImageSize(bytes);
  if (size == null) return null;
  return (bytes: bytes, width: size.width, height: size.height);
}

/// Optional platform/browser adapter that converts unsupported bytes to PNG.
typedef StudioImageDecodeAdapter = Future<Uint8List?> Function(Uint8List bytes);

/// Validates image bytes via encoded size probe, then an optional native adapter.
///
/// Pixel budgets are applied **before** any full-frame rasterization. Empty,
/// truncated, oversized, or unsupported payloads yield null (or a
/// [PhotoImportRejection] via [onRejected]) so callers can show an error
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

  Future<Uint8List?> acceptProbed(Uint8List bytes) async {
    final size = await readEncodedImageSize(bytes);
    if (size == null) return null;
    final sizeReject = PhotoImportGate.rejectDecodedSize(
      width: size.width,
      height: size.height,
    );
    if (sizeReject != null) {
      onRejected?.call(sizeReject);
      return null;
    }
    return bytes;
  }

  final directSize = await readEncodedImageSize(rawBytes);
  if (directSize != null) {
    final sizeReject = PhotoImportGate.rejectDecodedSize(
      width: directSize.width,
      height: directSize.height,
    );
    if (sizeReject != null) {
      onRejected?.call(sizeReject);
      return null;
    }
    return rawBytes;
  }

  // Encoded size unreadable (typical HEIC on hosts without HEIF codecs).
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

  final accepted = await acceptProbed(adapted);
  if (accepted != null) return accepted;
  // acceptProbed already reported tooManyPixels when applicable.
  if (await readEncodedImageSize(adapted) == null) {
    onRejected?.call(PhotoImportRejection.undecodable);
  }
  return null;
}
