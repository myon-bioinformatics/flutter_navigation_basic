// Pattern 029: TopN
// 上位 N 件の効率的な取得。

class Pattern029Result {
  const Pattern029Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern029Result.fromJson(Map<String, dynamic> json) =>
      Pattern029Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern029Result(message: $message)';
}
