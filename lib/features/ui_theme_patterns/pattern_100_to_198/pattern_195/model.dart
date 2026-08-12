// Pattern 195: LongPress
// 長押しアクション実装。

class Pattern195Result {
  const Pattern195Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern195Result.fromJson(Map<String, dynamic> json) =>
      Pattern195Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern195Result(message: $message)';
}
