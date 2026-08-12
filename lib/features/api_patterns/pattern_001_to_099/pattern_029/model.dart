// Pattern 029: Timeout
// タイムアウト付き HTTP リクエスト基本形。

class Pattern029Result {
  const Pattern029Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern029Result.fromJson(Map<String, dynamic> json) =>
      Pattern029Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern029Result(message: $message)';
}
