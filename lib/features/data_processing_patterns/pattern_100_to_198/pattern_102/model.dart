// Pattern 102: SanitizeInput
// XSS/SQLインジェクション防止の入力サニタイズ。

class Pattern102Result {
  const Pattern102Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern102Result.fromJson(Map<String, dynamic> json) =>
      Pattern102Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern102Result(message: $message)';
}
