// Pattern 109: Encoding
// 文字エンコーディング変換処理。

class Pattern109Result {
  const Pattern109Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern109Result.fromJson(Map<String, dynamic> json) =>
      Pattern109Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern109Result(message: $message)';
}
