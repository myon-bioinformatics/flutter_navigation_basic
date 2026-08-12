// Pattern 185: Subscription
// サブスクリプション選択→支払いフロー。

class Pattern185Result {
  const Pattern185Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern185Result.fromJson(Map<String, dynamic> json) =>
      Pattern185Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern185Result(message: $message)';
}
