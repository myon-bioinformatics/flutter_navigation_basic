// Pattern 049: Scopes
// OAuth2 スコープ管理実装。

class Pattern049Result {
  const Pattern049Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern049Result.fromJson(Map<String, dynamic> json) =>
      Pattern049Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern049Result(message: $message)';
}
