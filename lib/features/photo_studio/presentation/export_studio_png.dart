import 'dart:typed_data';

import '../domain/studio_document.dart';
import '../domain/studio_export_result.dart';
import 'compose_studio_image.dart';
import 'save_image_bytes.dart';

/// PNG-only export orchestration: capture → PNG encode → save.
///
/// Filename and MIME are fixed ([kStudioExportFileName] /
/// [kStudioExportMimeType]); JPEG / JPG / WebP are intentionally unsupported.
Future<StudioExportResult> exportStudioPng({
  required StudioDocument document,
  Future<bool> Function({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  })? saver,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final png = await composeStudioPng(document);
    final (width, height) = _pngIhDrSize(png);
    final save = saver ?? saveImageBytes;
    final ok = await save(
      bytes: png,
      fileName: kStudioExportFileName,
      mimeType: kStudioExportMimeType,
    );
    stopwatch.stop();
    return StudioExportResult(
      outcome:
          ok ? StudioExportOutcome.saved : StudioExportOutcome.unavailable,
      width: width,
      height: height,
      bytesLength: png.lengthInBytes,
      elapsedMilliseconds: stopwatch.elapsedMilliseconds,
    );
  } catch (_) {
    stopwatch.stop();
    return StudioExportResult(
      outcome: StudioExportOutcome.failed,
      width: 0,
      height: 0,
      bytesLength: 0,
      elapsedMilliseconds: stopwatch.elapsedMilliseconds,
    );
  }
}

(int, int) _pngIhDrSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}
