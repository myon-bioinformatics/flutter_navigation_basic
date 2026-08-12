// Pattern 099: JsonPath
// JSON Path 形式でネスト値を取得。

class Pattern099Result {
  const Pattern099Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern099Result.fromJson(Map<String, dynamic> json) =>
      Pattern099Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern099Result(message: $message)';
}
