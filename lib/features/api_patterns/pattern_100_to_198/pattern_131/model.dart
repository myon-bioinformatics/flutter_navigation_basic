// Pattern 131: ValidationError
// バリデーション失敗エラーの処理。

class Pattern131Result {
  const Pattern131Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern131Result.fromJson(Map<String, dynamic> json) =>
      Pattern131Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern131Result(message: $message)';
}
