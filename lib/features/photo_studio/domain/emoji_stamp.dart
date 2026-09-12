/// A stamp-like emoji overlay in normalized canvas space.
class EmojiStamp {
  const EmojiStamp({
    required this.emojiStampId,
    required this.emoji,
    required this.x,
    required this.y,
    this.scale = 1,
  });

  final String emojiStampId;
  final String emoji;

  /// Normalized center (0..1).
  final double x;
  final double y;

  /// Relative size; 1.0 ≈ 1/10 of the shorter canvas edge.
  final double scale;

  EmojiStamp copyWith({
    String? emojiStampId,
    String? emoji,
    double? x,
    double? y,
    double? scale,
  }) =>
      EmojiStamp(
        emojiStampId: emojiStampId ?? this.emojiStampId,
        emoji: emoji ?? this.emoji,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
      );
}

/// One-level undo snapshot of studio mutable state.
class PhotoStudioSnapshot {
  const PhotoStudioSnapshot({
    required this.imageBytes,
    required this.rectLeft,
    required this.rectTop,
    required this.rectRight,
    required this.rectBottom,
    required this.shapeName,
    required this.strokeArgb,
    required this.stamps,
    required this.selectedEmojiStampId,
    required this.stampScale,
  });

  final List<int>? imageBytes;
  final double rectLeft;
  final double rectTop;
  final double rectRight;
  final double rectBottom;
  final String shapeName;
  final int strokeArgb;
  final List<EmojiStamp> stamps;
  final String? selectedEmojiStampId;
  final double stampScale;
}
