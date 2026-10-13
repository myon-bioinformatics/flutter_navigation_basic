import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../features/photo_studio/data/photo_import_limits.dart';

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

  /// Shared decoded-byte ceiling for clipboard / paste Base64 image text.
  static int get maxClipboardImageBytes => PhotoImportLimits.maxInputBytes;

  /// Extra characters allowed for a `data:image/...;base64,` prefix on clipboard text.
  static const int dataUrlPrefixSlackChars = 256;

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

    // Probe dimensions without a full-size raster, then decode once at target.
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? scaledCodec;
    ui.Image? scaledImage;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(source);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final sourceWidth = descriptor.width;
      final sourceHeight = descriptor.height;
      if (sourceWidth <= 0 || sourceHeight <= 0) {
        throw const FormatException('Image dimensions are invalid.');
      }

      var target = targetDimensions(
        width: sourceWidth,
        height: sourceHeight,
        scale: scale,
      );
      final longEdge =
          target.width > target.height ? target.width : target.height;
      if (longEdge > maxLongEdge) {
        final fit = maxLongEdge / longEdge;
        target = (
          width: (target.width * fit).round().clamp(1, sourceWidth).toInt(),
          height: (target.height * fit).round().clamp(1, sourceHeight).toInt(),
        );
      }

      scaledCodec = await descriptor.instantiateCodec(
        targetWidth: target.width,
        targetHeight: target.height,
      );
      final scaledFrame = await scaledCodec.getNextFrame();
      scaledImage = scaledFrame.image;
      final pngData =
          await scaledImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) {
        throw StateError('Flutter could not encode the resized image as PNG.');
      }
      final pngBytes = Uint8List.fromList(
        pngData.buffer.asUint8List(
          pngData.offsetInBytes,
          pngData.lengthInBytes,
        ),
      );
      return Base64ImagePayload(
        bytes: pngBytes,
        mimeType: 'image/png',
      );
    } finally {
      scaledImage?.dispose();
      scaledCodec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Upper bound of Base64 characters for [maxBytes] decoded bytes (`=` padding
  /// included, whitespace and any `data:` prefix excluded).
  static int maxBase64Chars(int maxBytes) => 4 * ((maxBytes + 2) ~/ 3);

  /// Max clipboard text length when a data URL prefix may precede the payload.
  static int maxClipboardTextChars(int maxBytes) =>
      maxBase64Chars(maxBytes) + dataUrlPrefixSlackChars;

  /// True when compact Base64 in [text] would exceed [maxBytes] after decode.
  static bool textExceedsMaxImageBytes(String text, int maxBytes) {
    var trimmed = _stripBom(text).trim();
    if (trimmed.isEmpty) return false;
    final dataUrl = _dataUrlPattern.firstMatch(trimmed);
    if (dataUrl != null) {
      trimmed = trimmed.substring(dataUrl.end);
    } else if (trimmed.length >= 5 && trimmed.substring(0, 5).toLowerCase() == 'data:') {
      // A malformed header is a format error, not evidence of a byte overflow.
      // Let decodeText reject it before decoding or allocating image bytes.
      return false;
    }
    final encoded = trimmed.replaceAll(RegExp(r'\s+'), '');
    return encoded.length > maxBase64Chars(maxBytes);
  }

  /// Whether clipboard text should be tried as an image: an image data URL
  /// (any letter case) or raw standard Base64, possibly line-wrapped.
  static bool looksLikeImageText(String value, {int minChars = 80}) {
    final text = _stripBom(value).trim();
    if (text.length >= 11 && text.substring(0, 11).toLowerCase() == 'data:image/') {
      return true;
    }
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    return compact.length >= minChars &&
        compact.length % 4 == 0 &&
        _base64Pattern.hasMatch(compact);
  }

  static final RegExp _dataUrlPattern = RegExp(
    r'^data:([a-z0-9.+-]+/[a-z0-9.+-]+)?((?:;[a-z0-9.+-]+=[a-z0-9.+-]+)*);base64,',
    caseSensitive: false,
  );
  static final RegExp _base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');

  static String _stripBom(String value) =>
      value.startsWith('\uFEFF') ? value.substring(1) : value;

  /// Image MIME type from magic bytes, or null when not PNG/JPEG/WebP.
  static String? sniffMimeType(Uint8List bytes) {
    bool at(int offset, List<int> sig) {
      if (bytes.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (bytes[offset + i] != sig[i]) return false;
      }
      return true;
    }

    if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    if (at(0, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (at(0, const [0x52, 0x49, 0x46, 0x46]) && at(8, const [0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    return null;
  }

  /// [decodeText] for clipboard shelf paste (uses [maxClipboardImageBytes]).
  static Base64ImagePayload decodeClipboardShelfText(String input) => decodeText(input);

  /// Strictly decodes raw Base64 or a `data:image/...;base64,` URL.
  ///
  /// The declared type must match the decoded bytes; `;key=value` parameters
  /// are ignored; URL-safe characters, `%3D` and missing padding are rejected.
  ///
  /// When [maxBytes] is omitted, [PhotoImportLimits.maxInputBytes] is enforced.
  static Base64ImagePayload decodeText(String input, {int? maxBytes}) {
    final byteLimit = maxBytes ?? PhotoImportLimits.maxInputBytes;
    var text = _stripBom(input).trim();
    if (text.isEmpty) throw const FormatException('Base64 input is empty.');

    String? declared;
    final dataUrl = _dataUrlPattern.firstMatch(text);
    if (dataUrl != null) {
      declared = dataUrl.group(1)?.toLowerCase();
      if (declared == 'image/jpg') declared = 'image/jpeg';
      text = text.substring(dataUrl.end);
    } else if (text.length >= 5 && text.substring(0, 5).toLowerCase() == 'data:') {
      throw const FormatException(
        'Data URL must be base64-encoded (data:<type>;base64,...) '
        'with plain ;key=value parameters only.',
      );
    }
    if (declared != null && !supportedRasterMimeTypes.contains(declared)) {
      throw FormatException(
        'Unsupported image MIME type: $declared. Use PNG, JPEG, or WebP.',
      );
    }
    final encoded = text.replaceAll(RegExp(r'\s+'), '');
    if (encoded.isEmpty) throw const FormatException('Base64 input is empty.');
    if (encoded.length > maxBase64Chars(byteLimit)) {
      throw FormatException('Base64 image exceeds $byteLimit bytes.');
    }
    if (encoded.length % 4 != 0 || !_base64Pattern.hasMatch(encoded)) {
      throw const FormatException(
        'Invalid Base64 (standard A-Z a-z 0-9 + / with = padding; '
        'URL-safe, %3D and unpadded input are rejected).',
      );
    }
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty) {
      throw const FormatException('Decoded image bytes are empty.');
    }
    if (bytes.length > byteLimit) {
      throw FormatException('Base64 image exceeds $byteLimit bytes.');
    }
    final actual = sniffMimeType(bytes);
    if (actual == null) {
      throw const FormatException(
        'Decoded bytes are not a PNG, JPEG, or WebP image.',
      );
    }
    if (declared != null && declared != actual) {
      throw FormatException('Data URL says $declared but the bytes are $actual.');
    }
    return Base64ImagePayload(bytes: bytes, mimeType: actual);
  }
}
