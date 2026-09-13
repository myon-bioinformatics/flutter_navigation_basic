import 'dart:typed_data';

import '../domain/studio_document.dart';
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
Future<Uint8List> composeStudioPng(StudioDocument document) async {
  final image = await captureStudioCanvas(document);
  return encodeStudioPng(image);
}
