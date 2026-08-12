// Pattern 100: AMOLED
// AMOLED 向け純黒ダークモード実装。

class Pattern100Result {
  const Pattern100Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern100Result.fromJson(Map<String, dynamic> json) =>
      Pattern100Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern100Result(message: $message)';
}
