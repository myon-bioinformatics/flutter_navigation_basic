// Pattern 107: JsonSchema
// JSON Schema バリデーション (手動実装)。

class Pattern107Result {
  const Pattern107Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern107Result.fromJson(Map<String, dynamic> json) =>
      Pattern107Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern107Result(message: $message)';
}
