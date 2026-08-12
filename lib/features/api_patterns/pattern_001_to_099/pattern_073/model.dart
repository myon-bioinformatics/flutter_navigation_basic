// Pattern 073: SseEventType
// SSE 名前付きイベントの処理。

class Pattern073Result {
  const Pattern073Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern073Result.fromJson(Map<String, dynamic> json) =>
      Pattern073Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern073Result(message: $message)';
}
