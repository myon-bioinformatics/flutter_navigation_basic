// Pattern 085: CardTheme
// CardTheme のカスタマイズ。

class Pattern085Result {
  const Pattern085Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern085Result.fromJson(Map<String, dynamic> json) =>
      Pattern085Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern085Result(message: $message)';
}
