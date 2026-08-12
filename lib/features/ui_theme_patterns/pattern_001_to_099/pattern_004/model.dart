// Pattern 004: OutlinedButton
// OutlinedButton のスタイル実装。

class Pattern004Result {
  const Pattern004Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern004Result.fromJson(Map<String, dynamic> json) =>
      Pattern004Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern004Result(message: $message)';
}
