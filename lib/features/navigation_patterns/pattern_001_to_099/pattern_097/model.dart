// Pattern 097: DarkModeConditional
// ダークモード対応条件付き UI 遷移。

class Pattern097Result {
  const Pattern097Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern097Result.fromJson(Map<String, dynamic> json) =>
      Pattern097Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern097Result(message: $message)';
}
