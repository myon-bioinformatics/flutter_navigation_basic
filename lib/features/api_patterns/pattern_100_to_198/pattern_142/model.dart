// Pattern 142: ErrorReporting
// エラーをリモートサービスに送信 (擬似)。

class Pattern142Result {
  const Pattern142Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern142Result.fromJson(Map<String, dynamic> json) =>
      Pattern142Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern142Result(message: $message)';
}
