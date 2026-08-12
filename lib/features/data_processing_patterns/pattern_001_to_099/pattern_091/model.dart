// Pattern 091: ValidationBasic
// 基本的な入力バリデーション実装。

class Pattern091Result {
  const Pattern091Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern091Result.fromJson(Map<String, dynamic> json) =>
      Pattern091Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern091Result(message: $message)';
}
