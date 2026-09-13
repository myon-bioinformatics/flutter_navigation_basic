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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiStamp &&
          emojiStampId == other.emojiStampId &&
          emoji == other.emoji &&
          x == other.x &&
          y == other.y &&
          scale == other.scale;

  @override
  int get hashCode => Object.hash(emojiStampId, emoji, x, y, scale);
}
