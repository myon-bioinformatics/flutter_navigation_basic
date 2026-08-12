// Pattern 161: NetworkFirst
// Network First フェッチ戦略。

class Pattern161Result {
  const Pattern161Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern161Result.fromJson(Map<String, dynamic> json) =>
      Pattern161Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern161Result(message: $message)';
}
