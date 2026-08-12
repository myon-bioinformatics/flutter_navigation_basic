// Pattern 100: AsyncValidation
// 非同期バリデーション (サーバー確認)。

class Pattern100Result {
  const Pattern100Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern100Result.fromJson(Map<String, dynamic> json) =>
      Pattern100Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern100Result(message: $message)';
}
