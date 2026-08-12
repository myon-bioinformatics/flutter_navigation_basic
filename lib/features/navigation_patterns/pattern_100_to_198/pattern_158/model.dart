// Pattern 158: ZoomTransition
// ズームイン/アウト遷移アニメーション。

class Pattern158Result {
  const Pattern158Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern158Result.fromJson(Map<String, dynamic> json) =>
      Pattern158Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern158Result(message: $message)';
}
