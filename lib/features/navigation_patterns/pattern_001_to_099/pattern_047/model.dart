// Pattern 047: DeepLinkAuthenticated
// 認証済みユーザー向けディープリンク。

class Pattern047Result {
  const Pattern047Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern047Result.fromJson(Map<String, dynamic> json) =>
      Pattern047Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern047Result(message: $message)';
}
