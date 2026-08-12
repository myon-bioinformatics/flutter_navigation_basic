// Pattern 104: TypeCoercion
// 型強制変換処理の安全な実装。

class Pattern104Result {
  const Pattern104Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern104Result.fromJson(Map<String, dynamic> json) =>
      Pattern104Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern104Result(message: $message)';
}
