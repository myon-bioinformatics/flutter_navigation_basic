// Pattern 035: JwtRefresh
// JWT リフレッシュトークンによる再認証。

class Pattern035Result {
  const Pattern035Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern035Result.fromJson(Map<String, dynamic> json) =>
      Pattern035Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern035Result(message: $message)';
}
