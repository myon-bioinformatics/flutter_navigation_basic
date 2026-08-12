// Pattern 102: JsonlStream
// JSONL をストリームとして処理。

class Pattern102Result {
  const Pattern102Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern102Result.fromJson(Map<String, dynamic> json) =>
      Pattern102Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern102Result(message: $message)';
}
