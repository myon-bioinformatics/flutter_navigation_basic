// Pattern 147: EventLoop
// イベントループの理解と制御。

class Pattern147Result {
  const Pattern147Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern147Result.fromJson(Map<String, dynamic> json) =>
      Pattern147Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern147Result(message: $message)';
}
