import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/studio_frame_style.dart';
import 'studio_canvas_capture.dart';
import 'studio_png_encode.dart';

/// Photo Studio export is PNG-only (filename `photo-studio.png`, MIME `image/png`).
/// JPEG / JPG / WebP are intentionally unsupported to keep dependencies thin.
const String kStudioExportFileName = 'photo-studio.png';
const String kStudioExportMimeType = 'image/png';

/// Capture + PNG-encode facade (does not save/download).
///
/// Prefer [exportStudioPng] when the full capture → encode → save path is needed.
/// Layers:
/// - capture: [captureStudioCanvas]
/// - encode: [encodeStudioPng]
/// - save: [saveImageBytes] / [exportStudioPng]
Future<Uint8List> composeStudioPng({
  required Size logicalSize,
  required NormalizedRect rect,
  required StudioFrameShape shape,
  required Color strokeColor,
  required List<EmojiStamp> stamps,
  Uint8List? imageBytes,
  double pixelRatio = 2,
}) async {
  final image = await captureStudioCanvas(
    logicalSize: logicalSize,
    rect: rect,
    shape: shape,
    strokeColor: strokeColor,
    stamps: stamps,
    imageBytes: imageBytes,
    pixelRatio: pixelRatio,
  );
  return encodeStudioPng(image);
}
