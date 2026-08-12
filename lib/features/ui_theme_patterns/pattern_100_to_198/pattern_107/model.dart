// Pattern 107: PrintMode
// 印刷向け白黒テーマ。

class Pattern107Result {
  const Pattern107Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern107Result.fromJson(Map<String, dynamic> json) =>
      Pattern107Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern107Result(message: $message)';
}
