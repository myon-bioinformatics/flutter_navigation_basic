import 'dart:collection';
import 'dart:typed_data';

import 'emoji_stamp.dart';
import 'studio_frame.dart';
import 'studio_frame_style.dart';

/// Immutable editable state for Photo Studio (history / undo unit).
///
/// Pure Dart — no Flutter imports. [imageBytes] is shared by reference across
/// history entries; [frames] and [stamps] are always stored as unmodifiable
/// lists.
class PhotoStudioState {
  PhotoStudioState({
    required this.imageBytes,
    required List<StudioFrame> frames,
    required this.selectedStudioFrameId,
    required this.draftStrokeArgb,
    required this.draftShape,
    required List<EmojiStamp> stamps,
    required this.selectedEmojiStampId,
    required this.stampScale,
  })  : frames = UnmodifiableListView<StudioFrame>(
          List<StudioFrame>.from(frames, growable: false),
        ),
        stamps = UnmodifiableListView<EmojiStamp>(
          List<EmojiStamp>.from(stamps, growable: false),
        );

  /// Default studio state before any user edits.
  ///
  /// No frames; draft tool is "none" so empty drags do not create.
  factory PhotoStudioState.initial() => PhotoStudioState(
        imageBytes: null,
        frames: const <StudioFrame>[],
        selectedStudioFrameId: null,
        draftStrokeArgb: StudioFrameColors.purple,
        draftShape: null,
        stamps: const <EmojiStamp>[],
        selectedEmojiStampId: null,
        stampScale: 1,
      );

  static const Object _unset = Object();

  final Uint8List? imageBytes;

  /// Unmodifiable frame list (copy-on-write at the constructor boundary).
  final List<StudioFrame> frames;
  final String? selectedStudioFrameId;

  /// Stroke color applied to newly created frames (and UI color picker).
  final int draftStrokeArgb;

  /// Active create tool; `null` means none (select/move only).
  final StudioFrameShape? draftShape;

  /// Unmodifiable stamp list (copy-on-write at the constructor boundary).
  final List<EmojiStamp> stamps;
  final String? selectedEmojiStampId;
  final double stampScale;

  StudioFrame? get selectedFrame {
    final studioFrameId = selectedStudioFrameId;
    if (studioFrameId == null) return null;
    for (final frame in frames) {
      if (frame.studioFrameId == studioFrameId) return frame;
    }
    return null;
  }

  PhotoStudioState copyWith({
    Object? imageBytes = _unset,
    List<StudioFrame>? frames,
    Object? selectedStudioFrameId = _unset,
    int? draftStrokeArgb,
    Object? draftShape = _unset,
    List<EmojiStamp>? stamps,
    Object? selectedEmojiStampId = _unset,
    double? stampScale,
  }) =>
      PhotoStudioState(
        imageBytes: identical(imageBytes, _unset)
            ? this.imageBytes
            : imageBytes as Uint8List?,
        frames: frames ?? this.frames,
        selectedStudioFrameId: identical(selectedStudioFrameId, _unset)
            ? this.selectedStudioFrameId
            : selectedStudioFrameId as String?,
        draftStrokeArgb: draftStrokeArgb ?? this.draftStrokeArgb,
        draftShape: identical(draftShape, _unset)
            ? this.draftShape
            : draftShape as StudioFrameShape?,
        stamps: stamps ?? this.stamps,
        selectedEmojiStampId: identical(selectedEmojiStampId, _unset)
            ? this.selectedEmojiStampId
            : selectedEmojiStampId as String?,
        stampScale: stampScale ?? this.stampScale,
      );

  /// Document content only (image / frames / stamps) — ignores selection & draft tools.
  bool sameDocumentAs(PhotoStudioState other) =>
      identical(imageBytes, other.imageBytes) &&
      _listEquals(frames, other.frames) &&
      _listEquals(stamps, other.stamps);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoStudioState &&
          identical(imageBytes, other.imageBytes) &&
          _listEquals(frames, other.frames) &&
          selectedStudioFrameId == other.selectedStudioFrameId &&
          draftStrokeArgb == other.draftStrokeArgb &&
          draftShape == other.draftShape &&
          _listEquals(stamps, other.stamps) &&
          selectedEmojiStampId == other.selectedEmojiStampId &&
          stampScale == other.stampScale;

  @override
  int get hashCode => Object.hash(
        identityHashCode(imageBytes),
        Object.hashAll(frames),
        selectedStudioFrameId,
        draftStrokeArgb,
        draftShape,
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
