// Pattern 087: NotificationWs
// WebSocket によるプッシュ通知受信。

class Pattern087Result {
  const Pattern087Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern087Result.fromJson(Map<String, dynamic> json) =>
      Pattern087Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern087Result(message: $message)';
}
