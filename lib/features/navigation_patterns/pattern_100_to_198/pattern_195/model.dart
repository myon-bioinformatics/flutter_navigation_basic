// Pattern 195: NotificationNav
// 通知タップ→詳細画面への遷移。

class Pattern195Result {
  const Pattern195Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern195Result.fromJson(Map<String, dynamic> json) =>
      Pattern195Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern195Result(message: $message)';
}
