// Pattern 124: FutureWait
// Future.wait による並列実行。

class Pattern124Result {
  const Pattern124Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern124Result.fromJson(Map<String, dynamic> json) =>
      Pattern124Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern124Result(message: $message)';
}
