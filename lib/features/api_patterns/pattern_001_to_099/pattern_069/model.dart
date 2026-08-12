// Pattern 069: WebSocketAuth
// WebSocket 接続時の認証トークン付与。

class Pattern069Result {
  const Pattern069Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern069Result.fromJson(Map<String, dynamic> json) =>
      Pattern069Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern069Result(message: $message)';
}
