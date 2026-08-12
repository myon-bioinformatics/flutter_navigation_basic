// Pattern 026: Cors
// CORS ヘッダー対応の HTTP リクエスト。

class Pattern026Result {
  const Pattern026Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern026Result.fromJson(Map<String, dynamic> json) =>
      Pattern026Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern026Result(message: $message)';
}
