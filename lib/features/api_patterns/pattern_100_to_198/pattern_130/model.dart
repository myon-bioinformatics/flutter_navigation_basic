// Pattern 130: UserFriendlyError
// ユーザー向けエラーメッセージの表示。

class Pattern130Result {
  const Pattern130Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern130Result.fromJson(Map<String, dynamic> json) =>
      Pattern130Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern130Result(message: $message)';
}
