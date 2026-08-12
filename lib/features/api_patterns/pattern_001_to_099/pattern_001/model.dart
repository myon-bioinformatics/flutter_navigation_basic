// Pattern 001: HttpGet
// 基本的な HTTP GET リクエスト実装。

class Pattern001Result {
  const Pattern001Result({
    required this.message,
    this.statusCode = 200,
    this.body = const {},
  });

  final String message;
  final int statusCode;
  final Map<String, dynamic> body;

  Map<String, dynamic> toJson() => {
        'message': message,
        'statusCode': statusCode,
        'body': body,
      };

  factory Pattern001Result.fromJson(Map<String, dynamic> json) =>
      Pattern001Result(
        message: json['message'] as String,
        statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
        body: (json['body'] as Map<String, dynamic>?) ?? {},
      );

  @override
  String toString() =>
      'Pattern001Result(statusCode: $statusCode, message: $message)';
}
