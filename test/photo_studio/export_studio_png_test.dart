import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_document.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_export_result.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/compose_studio_image.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/export_studio_png.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_canvas_capture.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_png_encode.dart';
import 'package:flutter_test/flutter_test.dart';

const _pngSignature = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

bool _isPng(Uint8List bytes) {
  if (bytes.length < _pngSignature.length) return false;
  for (var i = 0; i < _pngSignature.length; i++) {
    if (bytes[i] != _pngSignature[i]) return false;
  }
  return true;
}

(int, int) _pngSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

StudioDocument _doc({
  Size logicalCanvasSize = const Size(400, 280),
  List<StudioFrame> frames = const [],
  List<EmojiStamp> stamps = const [],
  Uint8List? imageBytes,
  double pixelRatio = 2,
}) =>
    StudioDocument(
      imageBytes: imageBytes,
      frames: frames,
      stamps: stamps,
      logicalCanvasSize: logicalCanvasSize,
      pixelRatio: pixelRatio,
    );

StudioFrame _frame({
  String id = 'frame-a',
  NormalizedRect rect = NormalizedRect.initial,
  StudioFrameShape shape = StudioFrameShape.rectangle,
  int strokeArgb = 0xFF7C4DFF,
}) =>
    StudioFrame(
      studioFrameId: id,
      rect: rect,
      shape: shape,
      strokeArgb: strokeArgb,
    );

void main() {
  test('capture → encode layers produce PNG at logicalSize × pixelRatio',
      () async {
    final image = await captureStudioCanvas(
      _doc(
        frames: [_frame()],
        stamps: const [
          EmojiStamp(emojiStampId: 'stamp-a', emoji: '⭐', x: 0.5, y: 0.5),
        ],
      ),
    );
    expect(image.width, 800);
    expect(image.height, 560);

    final bytes = await encodeStudioPng(image);
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 800);
    expect(h, 560);
  });

  test('capture draws multiple frames', () async {
    final image = await captureStudioCanvas(
      _doc(
        frames: [
          _frame(id: 'a', shape: StudioFrameShape.rectangle),
          _frame(
            id: 'b',
            shape: StudioFrameShape.circle,
            rect: const NormalizedRect(
              left: 0.05,
              top: 0.05,
              right: 0.35,
              bottom: 0.35,
            ),
            strokeArgb: 0xFF00AA55,
          ),
        ],
      ),
    );
    expect(image.width, 800);
    expect(image.height, 560);
    image.dispose();
  });

  test('encodeStudioPng returns PNG and takes ownership of the image', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 4, 4),
      Paint()..color = const Color(0xFFFF0000),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    picture.dispose();

    final bytes = await encodeStudioPng(image);
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 4);
    expect(h, 4);
  });

  test('uint8ListFromByteData respects non-zero ByteData offset', () {
    final pngRange = Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
    ]);
    final larger = Uint8List(pngRange.length + 16);
    larger.setRange(0, 8, List<int>.filled(8, 0xAA));
    larger.setRange(8, 8 + pngRange.length, pngRange);
    larger.setRange(
      8 + pngRange.length,
      larger.length,
      List<int>.filled(8, 0xBB),
    );

    final view = ByteData.sublistView(larger, 8, 8 + pngRange.length);
    expect(view.offsetInBytes, 8);
    expect(view.lengthInBytes, pngRange.length);

    final sliced = uint8ListFromByteData(view);
    expect(sliced, orderedEquals(pngRange));
    expect(sliced.length, pngRange.length);
    // Bare buffer.asUint8List() would include the 0xAA prefix.
    expect(sliced[0], 0x89);
    expect(sliced, isNot(orderedEquals(larger)));
  });

  test('exportStudioPng returns StudioExportResult with PNG metadata', () async {
    String? savedName;
    String? savedMime;
    Uint8List? savedBytes;

    final result = await exportStudioPng(
      document: _doc(
        logicalCanvasSize: const Size(200, 100),
        frames: [
          _frame(shape: StudioFrameShape.circle, strokeArgb: 0xFF00AA55),
        ],
      ),
      saver: ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        savedName = fileName;
        savedMime = mimeType;
        savedBytes = bytes;
        return true;
      },
    );

    expect(result.outcome, StudioExportOutcome.saved);
    expect(result.width, 400);
    expect(result.height, 200);
    expect(result.bytesLength, greaterThan(0));
    expect(result.elapsedMilliseconds, greaterThanOrEqualTo(0));
    expect(savedName, kStudioExportFileName);
    expect(savedMime, kStudioExportMimeType);
    expect(savedBytes, isNotNull);
    expect(_isPng(savedBytes!), isTrue);
  });

  test('exportStudioPng maps saver false to unavailable', () async {
    final result = await exportStudioPng(
      document: _doc(logicalCanvasSize: const Size(50, 50), pixelRatio: 1),
      saver: ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async =>
          false,
    );
    expect(result.outcome, StudioExportOutcome.unavailable);
    expect(result.width, 50);
    expect(result.height, 50);
    expect(result.bytesLength, greaterThan(0));
  });

  test('exportStudioPng maps saver exception to failed', () async {
    final result = await exportStudioPng(
      document: _doc(logicalCanvasSize: const Size(50, 50), pixelRatio: 1),
      saver: ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        throw StateError('save failed');
      },
    );
    expect(result.outcome, StudioExportOutcome.failed);
    expect(result.width, 0);
    expect(result.height, 0);
    expect(result.bytesLength, 0);
  });

  test('composeStudioPng remains a capture+encode facade', () async {
    final bytes = await composeStudioPng(
      _doc(
        logicalCanvasSize: const Size(100, 50),
        frames: [
          _frame(shape: StudioFrameShape.triangle, strokeArgb: 0xFF333333),
        ],
        pixelRatio: 1,
      ),
    );
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 100);
    expect(h, 50);
  });
}
