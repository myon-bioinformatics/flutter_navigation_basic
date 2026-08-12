// Pattern 118: JsonStream
// 大容量 JSON のストリームパース。

class Pattern118Result {
  const Pattern118Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern118Result.fromJson(Map<String, dynamic> json) =>
      Pattern118Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern118Result(message: $message)';
}
