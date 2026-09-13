import 'package:flutter/foundation.dart';

import 'emoji_stamp.dart';
import 'normalized_rect.dart';
import 'studio_frame_style.dart';

/// Immutable editable state for Photo Studio (history / undo unit).
@immutable
class PhotoStudioState {
  const PhotoStudioState({
    required this.imageBytes,
    required this.rect,
    required this.shape,
    required this.strokeArgb,
    required this.stamps,
    required this.selectedEmojiStampId,
    required this.stampScale,
  });

  /// Default studio state before any user edits.
  factory PhotoStudioState.initial() => const PhotoStudioState(
        imageBytes: null,
        rect: NormalizedRect.initial,
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
        stamps: <EmojiStamp>[],
        selectedEmojiStampId: null,
        stampScale: 1,
      );

  static const Object _unset = Object();

  final Uint8List? imageBytes;
  final NormalizedRect rect;
  final StudioFrameShape shape;
  final int strokeArgb;
  final List<EmojiStamp> stamps;
  final String? selectedEmojiStampId;
  final double stampScale;

  PhotoStudioState copyWith({
    Object? imageBytes = _unset,
    NormalizedRect? rect,
    StudioFrameShape? shape,
    int? strokeArgb,
    List<EmojiStamp>? stamps,
    Object? selectedEmojiStampId = _unset,
    double? stampScale,
  }) =>
      PhotoStudioState(
        imageBytes: identical(imageBytes, _unset)
            ? this.imageBytes
            : imageBytes as Uint8List?,
        rect: rect ?? this.rect,
        shape: shape ?? this.shape,
        strokeArgb: strokeArgb ?? this.strokeArgb,
        stamps: stamps ?? this.stamps,
        selectedEmojiStampId: identical(selectedEmojiStampId, _unset)
            ? this.selectedEmojiStampId
            : selectedEmojiStampId as String?,
        stampScale: stampScale ?? this.stampScale,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoStudioState &&
          identical(imageBytes, other.imageBytes) &&
          rect == other.rect &&
          shape == other.shape &&
          strokeArgb == other.strokeArgb &&
          listEquals(stamps, other.stamps) &&
          selectedEmojiStampId == other.selectedEmojiStampId &&
          stampScale == other.stampScale;

  @override
  int get hashCode => Object.hash(
        identityHashCode(imageBytes),
        rect,
        shape,
        strokeArgb,
        Object.hashAll(stamps),
        selectedEmojiStampId,
        stampScale,
      );
}
