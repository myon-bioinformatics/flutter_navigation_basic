// Pattern 185: ReduceMotion
// モーション低減設定の検出と対応。

class Pattern185Result {
  const Pattern185Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern185Result.fromJson(Map<String, dynamic> json) =>
      Pattern185Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern185Result(message: $message)';
}
