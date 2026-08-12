// Pattern 141: AnimatedPageRoute
// カスタム PageRoute アニメーション。

class Pattern141Result {
  const Pattern141Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern141Result.fromJson(Map<String, dynamic> json) =>
      Pattern141Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern141Result(message: $message)';
}
