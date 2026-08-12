// Pattern 198: AnimatedFeedback
// タップフィードバックアニメーション。

class Pattern198Result {
  const Pattern198Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern198Result.fromJson(Map<String, dynamic> json) =>
      Pattern198Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern198Result(message: $message)';
}
