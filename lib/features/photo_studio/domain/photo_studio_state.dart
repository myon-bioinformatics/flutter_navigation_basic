import 'dart:collection';
import 'dart:typed_data';

import 'emoji_stamp.dart';
import 'normalized_rect.dart';
import 'studio_frame_style.dart';

/// Immutable editable state for Photo Studio (history / undo unit).
///
/// Pure Dart — no Flutter imports. [imageBytes] is shared by reference across
/// history entries; [stamps] is always stored as an unmodifiable list.
class PhotoStudioState {
  PhotoStudioState({
    required this.imageBytes,
    required this.rect,
    required this.shape,
    required this.strokeArgb,
    required List<EmojiStamp> stamps,
    required this.selectedEmojiStampId,
    required this.stampScale,
  }) : stamps = UnmodifiableListView<EmojiStamp>(
          List<EmojiStamp>.from(stamps, growable: false),
        );

  /// Default studio state before any user edits.
  factory PhotoStudioState.initial() => PhotoStudioState(
        imageBytes: null,
        rect: NormalizedRect.initial,
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
        stamps: const <EmojiStamp>[],
        selectedEmojiStampId: null,
        stampScale: 1,
      );

  static const Object _unset = Object();

  final Uint8List? imageBytes;
  final NormalizedRect rect;
  final StudioFrameShape shape;
  final int strokeArgb;

  /// Unmodifiable stamp list (copy-on-write at the constructor boundary).
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
          _listEquals(stamps, other.stamps) &&
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
