// Pattern 189: PubSub
// Pub/Sub パターンの実装。

class Pattern189Result {
  const Pattern189Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern189Result.fromJson(Map<String, dynamic> json) =>
      Pattern189Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern189Result(message: $message)';
}
