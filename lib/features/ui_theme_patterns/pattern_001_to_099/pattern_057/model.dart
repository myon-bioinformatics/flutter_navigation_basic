// Pattern 057: PlatformDetect
// 実行プラットフォームの検出と分岐。

class Pattern057Result {
  const Pattern057Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern057Result.fromJson(Map<String, dynamic> json) =>
      Pattern057Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern057Result(message: $message)';
}
