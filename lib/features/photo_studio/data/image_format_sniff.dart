import 'dart:typed_data';

import 'photo_media_ports.dart';

/// Best-effort container/codec hint from magic bytes (no decode, no EXIF/GPS).
///
/// Safe for status copy: returns only coarse format labels, never payloads.
enum ImageFormatKind {
  empty,
  png,
  jpeg,
  webp,
  gif,
  avif,
  heic,
  unknown,
}

/// Result of [sniffImageFormat].
class ImageFormatSniff {
  const ImageFormatSniff({
    required this.kind,
    this.brand,
    this.jpegProgressive,
    this.jpegExifOrientation,
  });

  final ImageFormatKind kind;

  /// ISOBMFF brand when [kind] is [ImageFormatKind.heic] or [ImageFormatKind.avif].
  final String? brand;

  /// True when a progressive SOF2 marker is present (JPEG only).
  final bool? jpegProgressive;

  /// EXIF Orientation 1–8 when present and parseable; otherwise null.
  final int? jpegExifOrientation;

  String get label => switch (kind) {
        ImageFormatKind.empty => 'empty',
        ImageFormatKind.png => 'PNG',
        ImageFormatKind.jpeg => 'JPEG',
        ImageFormatKind.webp => 'WebP',
        ImageFormatKind.gif => 'GIF',
        ImageFormatKind.avif => 'AVIF',
        ImageFormatKind.heic => 'HEIC',
        ImageFormatKind.unknown => 'unknown',
      };
}

/// Sniff encoded image bytes without allocating a raster or reading GPS.
ImageFormatSniff sniffImageFormat(Uint8List bytes) {
  if (bytes.isEmpty) {
    return const ImageFormatSniff(kind: ImageFormatKind.empty);
  }

  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return const ImageFormatSniff(kind: ImageFormatKind.png);
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return ImageFormatSniff(
      kind: ImageFormatKind.jpeg,
      jpegProgressive: _jpegHasProgressiveSof(bytes),
      jpegExifOrientation: _jpegExifOrientation(bytes),
    );
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return const ImageFormatSniff(kind: ImageFormatKind.webp);
  }

  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38 &&
      (bytes[4] == 0x39 || bytes[4] == 0x37) &&
      bytes[5] == 0x61) {
    return const ImageFormatSniff(kind: ImageFormatKind.gif);
  }

  final ftypBrand = _ftypBrand(bytes);
  if (ftypBrand != null) {
    if (PhotoImportGate.isHeicBrand(ftypBrand)) {
      return ImageFormatSniff(kind: ImageFormatKind.heic, brand: ftypBrand);
    }
    if (ftypBrand == 'avif' || ftypBrand == 'avis') {
      return ImageFormatSniff(kind: ImageFormatKind.avif, brand: ftypBrand);
    }
  }

  return const ImageFormatSniff(kind: ImageFormatKind.unknown);
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

String? _ftypBrand(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[4] != 0x66 ||
      bytes[5] != 0x74 ||
      bytes[6] != 0x79 ||
      bytes[7] != 0x70) {
    return null;
  }
  return String.fromCharCodes(bytes.sublist(8, 12));
}

bool _jpegHasProgressiveSof(Uint8List bytes) {
  var i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) return false;
    final marker = bytes[i + 1];
    if (marker == 0xD9 || marker == 0xDA) return false;
    if (marker == 0xC2) return true;
    if (marker == 0xC0 || marker == 0xC1) return false;
    if (marker >= 0xD0 && marker <= 0xD7) {
      i += 2;
      continue;
    }
    if (marker == 0x01 || marker == 0x00) {
      i += 2;
      continue;
    }
    if (i + 3 >= bytes.length) return false;
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    if (len < 2) return false;
    i += 2 + len;
  }
  return false;
}

int? _jpegExifOrientation(Uint8List bytes) {
  var i = 2;
  while (i + 8 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    if (marker == 0xD9 || marker == 0xDA) return null;
    if (marker == 0xE1) {
      final len = (bytes[i + 2] << 8) | bytes[i + 3];
      if (len < 8 || i + 2 + len > bytes.length) return null;
      final segment = bytes.sublist(i + 4, i + 2 + len);
      return _orientationFromExifApp1(segment);
    }
    if (marker >= 0xD0 && marker <= 0xD7) {
      i += 2;
      continue;
    }
    if (i + 3 >= bytes.length) return null;
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    if (len < 2) return null;
    i += 2 + len;
  }
  return null;
}

int? _orientationFromExifApp1(Uint8List segment) {
  // Expect "Exif\0\0" then TIFF header.
  if (segment.length < 14) return null;
  if (!(segment[0] == 0x45 &&
      segment[1] == 0x78 &&
      segment[2] == 0x69 &&
      segment[3] == 0x66 &&
      segment[4] == 0x00 &&
      segment[5] == 0x00)) {
    return null;
  }
  final tiff = segment.sublist(6);
  if (tiff.length < 8) return null;
  final littleEndian = tiff[0] == 0x49 && tiff[1] == 0x49;
  final bigEndian = tiff[0] == 0x4D && tiff[1] == 0x4D;
  if (!littleEndian && !bigEndian) return null;

  int u16(int offset) {
    if (offset + 1 >= tiff.length) return -1;
    return littleEndian
        ? tiff[offset] | (tiff[offset + 1] << 8)
        : (tiff[offset] << 8) | tiff[offset + 1];
  }

  int u32(int offset) {
    if (offset + 3 >= tiff.length) return -1;
    return littleEndian
        ? tiff[offset] |
            (tiff[offset + 1] << 8) |
            (tiff[offset + 2] << 16) |
            (tiff[offset + 3] << 24)
        : (tiff[offset] << 24) |
            (tiff[offset + 1] << 16) |
            (tiff[offset + 2] << 8) |
            tiff[offset + 3];
  }

  final ifd0 = u32(4);
  if (ifd0 < 0 || ifd0 + 2 > tiff.length) return null;
  final count = u16(ifd0);
  if (count < 0) return null;
  for (var e = 0; e < count; e++) {
    final entry = ifd0 + 2 + e * 12;
    if (entry + 12 > tiff.length) return null;
    final tag = u16(entry);
    if (tag != 0x0112) continue; // Orientation
    final type = u16(entry + 2);
    final valueCount = u32(entry + 4);
    if (type != 3 || valueCount != 1) return null;
    final value = u16(entry + 8);
    if (value >= 1 && value <= 8) return value;
    return null;
  }
  return null;
}
