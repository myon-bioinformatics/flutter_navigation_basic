// Pattern 122: RetryLogic
// 失敗時の固定間隔リトライ実装。

class Pattern122Result {
  const Pattern122Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern122Result.fromJson(Map<String, dynamic> json) =>
      Pattern122Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern122Result(message: $message)';
}
