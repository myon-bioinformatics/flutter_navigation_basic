// Pattern 104: Sepia
// セピア調テーマ実装。

class Pattern104Result {
  const Pattern104Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern104Result.fromJson(Map<String, dynamic> json) =>
      Pattern104Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern104Result(message: $message)';
}
