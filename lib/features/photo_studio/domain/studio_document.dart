import 'dart:typed_data';
import 'dart:ui' show Color, Size;

import 'emoji_stamp.dart';
import 'normalized_rect.dart';
import 'photo_studio_state.dart';
import 'studio_frame_style.dart';

/// Immutable render/export input for Photo Studio PNG capture.
///
/// Uses `dart:ui` for [Color]/[Size] only — not a Flutter widget dependency.
class StudioDocument {
  StudioDocument({
    required this.imageBytes,
    required this.rect,
    required this.shape,
    required this.strokeColor,
    required List<EmojiStamp> stamps,
    required this.logicalCanvasSize,
    this.pixelRatio = 2,
  }) : stamps = List<EmojiStamp>.unmodifiable(stamps);

  factory StudioDocument.fromState(
    PhotoStudioState state, {
    required Size logicalCanvasSize,
    double pixelRatio = 2,
  }) =>
      StudioDocument(
        imageBytes: state.imageBytes,
        rect: state.rect,
        shape: state.shape,
        strokeColor: Color(state.strokeArgb),
        stamps: state.stamps,
        logicalCanvasSize: logicalCanvasSize,
        pixelRatio: pixelRatio,
      );

  final Uint8List? imageBytes;
  final NormalizedRect rect;
  final StudioFrameShape shape;
  final Color strokeColor;
  final List<EmojiStamp> stamps;
  final Size logicalCanvasSize;
  final double pixelRatio;
}
