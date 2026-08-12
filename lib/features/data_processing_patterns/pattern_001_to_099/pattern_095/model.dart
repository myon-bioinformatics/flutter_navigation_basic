// Pattern 095: UrlValidation
// URL バリデーション実装。

class Pattern095Result {
  const Pattern095Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern095Result.fromJson(Map<String, dynamic> json) =>
      Pattern095Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern095Result(message: $message)';
}
