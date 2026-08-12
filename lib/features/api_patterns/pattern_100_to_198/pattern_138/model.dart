// Pattern 138: DeadlineExceeded
// タイムアウト超過エラー処理。

class Pattern138Result {
  const Pattern138Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern138Result.fromJson(Map<String, dynamic> json) =>
      Pattern138Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern138Result(message: $message)';
}
