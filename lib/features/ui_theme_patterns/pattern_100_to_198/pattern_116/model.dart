// Pattern 116: SystemBrightness
// システム輝度に連動するテーマ。

class Pattern116Result {
  const Pattern116Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern116Result.fromJson(Map<String, dynamic> json) =>
      Pattern116Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern116Result(message: $message)';
}
