// Pattern 086: AppBarTheme
// AppBarTheme のカスタマイズ。

class Pattern086Result {
  const Pattern086Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern086Result.fromJson(Map<String, dynamic> json) =>
      Pattern086Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern086Result(message: $message)';
}
