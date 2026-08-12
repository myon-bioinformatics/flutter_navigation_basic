// Pattern 063: ColorScheme
// ColorScheme.fromSeed によるカラー生成。

class Pattern063Result {
  const Pattern063Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern063Result.fromJson(Map<String, dynamic> json) =>
      Pattern063Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern063Result(message: $message)';
}
