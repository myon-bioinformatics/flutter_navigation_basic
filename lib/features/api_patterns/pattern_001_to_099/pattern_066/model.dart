// Pattern 066: WebSocketBinary
// WebSocket バイナリデータ送受信。

class Pattern066Result {
  const Pattern066Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern066Result.fromJson(Map<String, dynamic> json) =>
      Pattern066Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern066Result(message: $message)';
}
