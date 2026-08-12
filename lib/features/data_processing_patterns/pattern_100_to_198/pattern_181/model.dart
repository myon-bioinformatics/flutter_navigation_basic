// Pattern 181: CommandPattern
// Command パターンによる操作履歴管理。

class Pattern181Result {
  const Pattern181Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern181Result.fromJson(Map<String, dynamic> json) =>
      Pattern181Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern181Result(message: $message)';
}
