import 'dart:typed_data';
import 'dart:ui' show Size;

import 'emoji_stamp.dart';
import 'photo_studio_state.dart';
import 'studio_frame.dart';

/// Immutable render/export input for Photo Studio PNG capture.
///
/// Uses `dart:ui` for [Size] only — not a Flutter widget dependency.
class StudioDocument {
  StudioDocument({
    required this.imageBytes,
    required List<StudioFrame> frames,
    required List<EmojiStamp> stamps,
    required this.logicalCanvasSize,
    this.pixelRatio = 2,
  })  : frames = List<StudioFrame>.unmodifiable(frames),
        stamps = List<EmojiStamp>.unmodifiable(stamps);

  factory StudioDocument.fromState(
    PhotoStudioState state, {
    required Size logicalCanvasSize,
    double pixelRatio = 2,
  }) =>
      StudioDocument(
        imageBytes: state.imageBytes,
        frames: state.frames,
        stamps: state.stamps,
        logicalCanvasSize: logicalCanvasSize,
        pixelRatio: pixelRatio,
      );

  final Uint8List? imageBytes;
  final List<StudioFrame> frames;
  final List<EmojiStamp> stamps;
  final Size logicalCanvasSize;
  final double pixelRatio;
}
