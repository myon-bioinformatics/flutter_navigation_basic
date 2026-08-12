// Pattern 072: SseReconnect
// SSE 切断時の自動再接続。

class Pattern072Result {
  const Pattern072Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern072Result.fromJson(Map<String, dynamic> json) =>
      Pattern072Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern072Result(message: $message)';
}
