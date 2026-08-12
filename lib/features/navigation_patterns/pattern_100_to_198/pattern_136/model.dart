// Pattern 136: OverlayNavigator
// Overlay を使った独立ナビゲーション層。

class Pattern136Result {
  const Pattern136Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern136Result.fromJson(Map<String, dynamic> json) =>
      Pattern136Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern136Result(message: $message)';
}
