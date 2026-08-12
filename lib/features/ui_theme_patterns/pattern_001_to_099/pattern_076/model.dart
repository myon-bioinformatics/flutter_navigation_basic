// Pattern 076: RetroTheme
// レトロスタイルテーマ実装。

class Pattern076Result {
  const Pattern076Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern076Result.fromJson(Map<String, dynamic> json) =>
      Pattern076Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern076Result(message: $message)';
}
