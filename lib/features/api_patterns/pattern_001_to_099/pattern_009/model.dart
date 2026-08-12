// Pattern 009: JsonSerialize
// Dart オブジェクトを JSON に変換して送信。

class Pattern009Result {
  const Pattern009Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern009Result.fromJson(Map<String, dynamic> json) =>
      Pattern009Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern009Result(message: $message)';
}
