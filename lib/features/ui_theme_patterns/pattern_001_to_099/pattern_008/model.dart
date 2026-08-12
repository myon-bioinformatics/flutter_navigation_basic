// Pattern 008: Card
// Card ウィジェットのスタイルバリエーション。

class Pattern008Result {
  const Pattern008Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern008Result.fromJson(Map<String, dynamic> json) =>
      Pattern008Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern008Result(message: $message)';
}
