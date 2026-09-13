import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/studio_document.dart';
import '../domain/studio_frame_style.dart';

/// Captures the studio scene into a raster [ui.Image] (no encoding yet).
///
/// [StudioDocument.logicalCanvasSize] should match the on-screen canvas so
/// stamp/frame layout matches what the user sees (including narrow viewports).
Future<ui.Image> captureStudioCanvas(StudioDocument document) async {
  final logicalSize = document.logicalCanvasSize;
  final pixelRatio = document.pixelRatio;
  final width = (logicalSize.width * pixelRatio).round().clamp(1, 4096);
  final height = (logicalSize.height * pixelRatio).round().clamp(1, 4096);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width.toDouble(), height.toDouble());

  canvas.drawRect(
    Offset.zero & size,
    Paint()..color = const Color(0xFF2A2A2A),
  );

  ui.Codec? codec;
  ui.Image? decoded;
  ui.Picture? picture;
  try {
    final imageBytes = document.imageBytes;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      decoded = frame.image;
      final src = Rect.fromLTWH(
        0,
        0,
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      );
      final fitted = applyBoxFit(
        BoxFit.contain,
        Size(decoded.width.toDouble(), decoded.height.toDouble()),
        size,
      );
      final dst =
          Alignment.center.inscribe(fitted.destination, Offset.zero & size);
      canvas.drawImageRect(decoded, src, dst, Paint());
    }

    for (final frame in document.frames) {
      final rect = frame.rect;
      final pixel = Rect.fromLTRB(
        rect.left * size.width,
        rect.top * size.height,
        rect.right * size.width,
        rect.bottom * size.height,
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * pixelRatio
        ..color = Color(frame.strokeArgb);
      _paintFrame(canvas, pixel, frame.shape, stroke);
    }

    for (final stamp in document.stamps) {
      final fontSize =
          math.min(size.width, size.height) * 0.1 * stamp.scale.clamp(0.4, 3.0);
      final tp = TextPainter(
        text: TextSpan(text: stamp.emoji, style: TextStyle(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          stamp.x * size.width - tp.width / 2,
          stamp.y * size.height - tp.height / 2,
        ),
      );
    }

    picture = recorder.endRecording();
    return await picture.toImage(width, height);
  } finally {
    decoded?.dispose();
    codec?.dispose();
    picture?.dispose();
  }
}

void _paintFrame(
  Canvas canvas,
  Rect pixel,
  StudioFrameShape shape,
  Paint stroke,
) {
  switch (shape) {
    case StudioFrameShape.rectangle:
      canvas.drawRect(pixel, stroke);
    case StudioFrameShape.circle:
      canvas.drawCircle(
        pixel.center,
        math.min(pixel.width, pixel.height) / 2,
        stroke,
      );
    case StudioFrameShape.triangle:
      final path = Path()
        ..moveTo(pixel.center.dx, pixel.top)
        ..lineTo(pixel.right, pixel.bottom)
        ..lineTo(pixel.left, pixel.bottom)
        ..close();
      canvas.drawPath(path, stroke);
  }
}
