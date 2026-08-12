// Pattern 058: AdaptiveTextField
// プラットフォームに応じたテキスト入力。

class Pattern058Result {
  const Pattern058Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern058Result.fromJson(Map<String, dynamic> json) =>
      Pattern058Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern058Result(message: $message)';
}
