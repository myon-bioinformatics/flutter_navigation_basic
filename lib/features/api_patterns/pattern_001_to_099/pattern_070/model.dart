// Pattern 070: WebSocketStream
// Dart Stream として WebSocket を扱う。

class Pattern070Result {
  const Pattern070Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern070Result.fromJson(Map<String, dynamic> json) =>
      Pattern070Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern070Result(message: $message)';
}
