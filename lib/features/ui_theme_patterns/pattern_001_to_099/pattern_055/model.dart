// Pattern 055: CupertinoTheme
// CupertinoThemeData のカスタマイズ。

class Pattern055Result {
  const Pattern055Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern055Result.fromJson(Map<String, dynamic> json) =>
      Pattern055Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern055Result(message: $message)';
}
