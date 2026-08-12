// Pattern 064: TypographyTheme
// Typography + TextTheme のカスタマイズ。

class Pattern064Result {
  const Pattern064Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern064Result.fromJson(Map<String, dynamic> json) =>
      Pattern064Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern064Result(message: $message)';
}
