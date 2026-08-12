// Pattern 149: SuspendResume
// 非同期処理の一時停止と再開。

class Pattern149Result {
  const Pattern149Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern149Result.fromJson(Map<String, dynamic> json) =>
      Pattern149Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern149Result(message: $message)';
}
