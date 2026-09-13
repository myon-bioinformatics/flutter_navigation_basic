import 'normalized_rect.dart';
import 'studio_frame_style.dart';

/// One drawable frame annotation on the studio canvas.
class StudioFrame {
  const StudioFrame({
    required this.studioFrameId,
    required this.rect,
    required this.shape,
    required this.strokeArgb,
  });

  final String studioFrameId;
  final NormalizedRect rect;
  final StudioFrameShape shape;
  final int strokeArgb;

  StudioFrame copyWith({
    String? studioFrameId,
    NormalizedRect? rect,
    StudioFrameShape? shape,
    int? strokeArgb,
  }) =>
      StudioFrame(
        studioFrameId: studioFrameId ?? this.studioFrameId,
        rect: rect ?? this.rect,
        shape: shape ?? this.shape,
        strokeArgb: strokeArgb ?? this.strokeArgb,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudioFrame &&
          studioFrameId == other.studioFrameId &&
          rect == other.rect &&
          shape == other.shape &&
          strokeArgb == other.strokeArgb;

  @override
  int get hashCode =>
      Object.hash(studioFrameId, rect, shape, strokeArgb);
}
