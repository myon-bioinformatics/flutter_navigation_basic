// Pattern 080: MultiLevelNav
// 階層型マルチレベルナビゲーション。

class Pattern080Result {
  const Pattern080Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern080Result.fromJson(Map<String, dynamic> json) =>
      Pattern080Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern080Result(message: $message)';
}
