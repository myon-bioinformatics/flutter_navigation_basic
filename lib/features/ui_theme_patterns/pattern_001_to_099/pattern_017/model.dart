// Pattern 017: Badge
// Badge ウィジェットの実装。

class Pattern017Result {
  const Pattern017Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern017Result.fromJson(Map<String, dynamic> json) =>
      Pattern017Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern017Result(message: $message)';
}
