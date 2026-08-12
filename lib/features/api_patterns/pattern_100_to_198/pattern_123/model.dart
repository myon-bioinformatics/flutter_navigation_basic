// Pattern 123: ExponentialBackoff
// 指数バックオフリトライ実装。

class Pattern123Result {
  const Pattern123Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern123Result.fromJson(Map<String, dynamic> json) =>
      Pattern123Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern123Result(message: $message)';
}
