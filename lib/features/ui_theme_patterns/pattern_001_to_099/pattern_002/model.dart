// Pattern 002: ElevatedButton
// ElevatedButton のスタイルバリエーション。

class Pattern002Result {
  const Pattern002Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern002Result.fromJson(Map<String, dynamic> json) =>
      Pattern002Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern002Result(message: $message)';
}
