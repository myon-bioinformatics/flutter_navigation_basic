import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/emoji_stamp.dart';
import '../domain/normalized_rect.dart';
import '../domain/studio_frame_style.dart';
import 'compose_studio_image.dart';
import 'save_image_bytes.dart';

/// PNG-only export orchestration: capture → PNG encode → save.
///
/// Filename and MIME are fixed ([kStudioExportFileName] /
/// [kStudioExportMimeType]); JPEG / JPG / WebP are intentionally unsupported.
Future<bool> exportStudioPng({
  required Size logicalSize,
  required NormalizedRect rect,
  required StudioFrameShape shape,
  required Color strokeColor,
  required List<EmojiStamp> stamps,
  Uint8List? imageBytes,
  double pixelRatio = 2,
  Future<bool> Function({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  })? saver,
}) async {
  final png = await composeStudioPng(
    logicalSize: logicalSize,
    rect: rect,
    shape: shape,
    strokeColor: strokeColor,
    stamps: stamps,
    imageBytes: imageBytes,
    pixelRatio: pixelRatio,
  );
  final save = saver ?? saveImageBytes;
  return save(
    bytes: png,
    fileName: kStudioExportFileName,
    mimeType: kStudioExportMimeType,
  );
}
