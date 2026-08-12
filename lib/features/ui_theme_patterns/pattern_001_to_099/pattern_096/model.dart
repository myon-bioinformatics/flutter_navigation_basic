// Pattern 096: DarkModeColor
// ダークモードに適したカラーパレット。

class Pattern096Result {
  const Pattern096Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern096Result.fromJson(Map<String, dynamic> json) =>
      Pattern096Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern096Result(message: $message)';
}
