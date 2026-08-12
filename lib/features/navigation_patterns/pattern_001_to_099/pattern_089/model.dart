// Pattern 089: PermissionGuard
// 権限確認後に画面遷移。

class Pattern089Result {
  const Pattern089Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern089Result.fromJson(Map<String, dynamic> json) =>
      Pattern089Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern089Result(message: $message)';
}
