// Pattern 108: Dim
// 薄暗め (Dim) ダークモード実装。

class Pattern108Result {
  const Pattern108Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern108Result.fromJson(Map<String, dynamic> json) =>
      Pattern108Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern108Result(message: $message)';
}
