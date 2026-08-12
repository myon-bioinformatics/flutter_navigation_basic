// Pattern 002: HttpPost
// JSON ボディ付き HTTP POST リクエスト。

class Pattern002Result {
  const Pattern002Result({
    required this.message,
    this.statusCode = 200,
    this.echo = const {},
  });

  final String message;
  final int statusCode;
  final Map<String, dynamic> echo;

  Map<String, dynamic> toJson() => {
        'message': message,
        'statusCode': statusCode,
        'echo': echo,
      };

  factory Pattern002Result.fromJson(Map<String, dynamic> json) =>
      Pattern002Result(
        message: json['message'] as String,
        statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
        echo: (json['echo'] as Map<String, dynamic>?) ?? {},
      );

  @override
  String toString() =>
      'Pattern002Result(statusCode: $statusCode, message: $message)';
}
