// Pattern 126: Timeout2
// より詳細なタイムアウト制御。

class Pattern126Result {
  const Pattern126Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern126Result.fromJson(Map<String, dynamic> json) =>
      Pattern126Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern126Result(message: $message)';
}
