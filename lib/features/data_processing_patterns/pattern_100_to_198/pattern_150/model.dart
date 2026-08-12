// Pattern 150: AsyncGenerator
// 非同期ジェネレーター関数の実装。

class Pattern150Result {
  const Pattern150Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern150Result.fromJson(Map<String, dynamic> json) =>
      Pattern150Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern150Result(message: $message)';
}
