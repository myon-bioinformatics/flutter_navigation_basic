// Pattern 158: CacheInvalidate
// 手動キャッシュ無効化実装。

class Pattern158Result {
  const Pattern158Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern158Result.fromJson(Map<String, dynamic> json) =>
      Pattern158Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern158Result(message: $message)';
}
