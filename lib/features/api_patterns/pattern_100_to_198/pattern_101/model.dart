// Pattern 101: JsonlWrite
// JSONL 形式への書き込み実装。

class Pattern101Result {
  const Pattern101Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern101Result.fromJson(Map<String, dynamic> json) =>
      Pattern101Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern101Result(message: $message)';
}
