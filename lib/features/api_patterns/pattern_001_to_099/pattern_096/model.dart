// Pattern 096: ModelToJson
// Dart クラスを JSON 文字列に直列化。

class Pattern096Result {
  const Pattern096Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern096Result.fromJson(Map<String, dynamic> json) =>
      Pattern096Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern096Result(message: $message)';
}
