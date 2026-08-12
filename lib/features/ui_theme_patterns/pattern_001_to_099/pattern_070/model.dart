// Pattern 070: ThemePersist
// テーマ設定を SharedPreferences で永続化。

class Pattern070Result {
  const Pattern070Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern070Result.fromJson(Map<String, dynamic> json) =>
      Pattern070Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern070Result(message: $message)';
}
