// Pattern 005: IconButton
// アイコンボタンのバリエーション。

class Pattern005Result {
  const Pattern005Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern005Result.fromJson(Map<String, dynamic> json) =>
      Pattern005Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern005Result(message: $message)';
}
