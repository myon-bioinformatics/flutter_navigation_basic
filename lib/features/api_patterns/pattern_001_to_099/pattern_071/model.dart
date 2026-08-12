// Pattern 071: SseBasic
// 基本的な SSE (Server-Sent Events) 受信。

class Pattern071Result {
  const Pattern071Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern071Result.fromJson(Map<String, dynamic> json) =>
      Pattern071Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern071Result(message: $message)';
}
