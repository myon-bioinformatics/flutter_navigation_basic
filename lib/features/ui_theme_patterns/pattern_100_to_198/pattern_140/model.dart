// Pattern 140: Scrollbar
// カスタムスクロールバー実装。

class Pattern140Result {
  const Pattern140Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern140Result.fromJson(Map<String, dynamic> json) =>
      Pattern140Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern140Result(message: $message)';
}
