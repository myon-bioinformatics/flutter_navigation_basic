// Pattern 010: TextField
// TextField と InputDecoration のスタイル。

class Pattern010Result {
  const Pattern010Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern010Result.fromJson(Map<String, dynamic> json) =>
      Pattern010Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern010Result(message: $message)';
}
