// Pattern 116: PopResult
// 前画面に結果を返して閉じる。

class Pattern116Result {
  const Pattern116Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern116Result.fromJson(Map<String, dynamic> json) =>
      Pattern116Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern116Result(message: $message)';
}
