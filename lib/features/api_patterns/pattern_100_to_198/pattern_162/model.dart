// Pattern 162: CacheOnly
// Cache Only フェッチ戦略。

class Pattern162Result {
  const Pattern162Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern162Result.fromJson(Map<String, dynamic> json) =>
      Pattern162Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern162Result(message: $message)';
}
