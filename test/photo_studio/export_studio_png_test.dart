import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
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

void main() {
  test('capture → encode layers produce PNG at logicalSize × pixelRatio',
      () async {
    final image = await captureStudioCanvas(
      logicalSize: const Size(400, 280),
      rect: NormalizedRect.initial,
      shape: StudioFrameShape.rectangle,
      strokeColor: const Color(0xFF7C4DFF),
      stamps: const [
        EmojiStamp(emojiStampId: 'stamp-a', emoji: '⭐', x: 0.5, y: 0.5),
      ],
    );
    expect(image.width, 800);
    expect(image.height, 560);

    final bytes = await encodeStudioPng(image);
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 800);
    expect(h, 560);
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

  test('exportStudioPng uses fixed PNG name/mime via injectable saver',
      () async {
    String? savedName;
    String? savedMime;
    Uint8List? savedBytes;

    final ok = await exportStudioPng(
      logicalSize: const Size(200, 100),
      rect: NormalizedRect.initial,
      shape: StudioFrameShape.circle,
      strokeColor: const Color(0xFF00AA55),
      stamps: const [],
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

    expect(ok, isTrue);
    expect(savedName, kStudioExportFileName);
    expect(savedMime, kStudioExportMimeType);
    expect(savedBytes, isNotNull);
    expect(_isPng(savedBytes!), isTrue);
    final (w, h) = _pngSize(savedBytes!);
    expect(w, 400);
    expect(h, 200);
  });

  test('composeStudioPng remains a capture+encode facade', () async {
    final bytes = await composeStudioPng(
      logicalSize: const Size(100, 50),
      rect: NormalizedRect.initial,
      shape: StudioFrameShape.triangle,
      strokeColor: const Color(0xFF333333),
      stamps: const [],
      pixelRatio: 1,
    );
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 100);
    expect(h, 50);
  });
}
