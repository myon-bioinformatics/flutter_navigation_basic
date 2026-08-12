// Pattern 042: RequestSigning
// リクエスト署名 (タイムスタンプ+署名)。

class Pattern042Result {
  const Pattern042Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern042Result.fromJson(Map<String, dynamic> json) =>
      Pattern042Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern042Result(message: $message)';
}
