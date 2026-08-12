// Pattern 014: Filtering
// サーバーサイドフィルタリング付き GET。

class Pattern014Result {
  const Pattern014Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern014Result.fromJson(Map<String, dynamic> json) =>
      Pattern014Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern014Result(message: $message)';
}
