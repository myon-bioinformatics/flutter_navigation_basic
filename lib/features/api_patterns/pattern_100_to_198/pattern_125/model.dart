// Pattern 125: Fallback
// エラー時のフォールバック値返却。

class Pattern125Result {
  const Pattern125Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern125Result.fromJson(Map<String, dynamic> json) =>
      Pattern125Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern125Result(message: $message)';
}
