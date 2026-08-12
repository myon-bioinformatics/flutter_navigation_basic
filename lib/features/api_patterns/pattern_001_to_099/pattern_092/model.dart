// Pattern 092: JsonNested
// ネスト JSON の再帰的パース。

class Pattern092Result {
  const Pattern092Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern092Result.fromJson(Map<String, dynamic> json) =>
      Pattern092Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern092Result(message: $message)';
}
