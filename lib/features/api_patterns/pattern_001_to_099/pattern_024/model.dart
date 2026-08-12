// Pattern 024: ContentNeg
// Content-Type ネゴシエーション実装。

class Pattern024Result {
  const Pattern024Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern024Result.fromJson(Map<String, dynamic> json) =>
      Pattern024Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern024Result(message: $message)';
}
