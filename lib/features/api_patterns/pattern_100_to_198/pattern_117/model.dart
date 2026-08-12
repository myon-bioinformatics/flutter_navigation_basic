// Pattern 117: JsonEncoding
// 文字エンコーディング対応 JSON 処理。

class Pattern117Result {
  const Pattern117Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern117Result.fromJson(Map<String, dynamic> json) =>
      Pattern117Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern117Result(message: $message)';
}
