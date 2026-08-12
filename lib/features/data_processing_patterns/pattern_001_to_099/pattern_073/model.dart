// Pattern 073: CacheEviction
// キャッシュ立ち退き (Eviction) 実装。

class Pattern073Result {
  const Pattern073Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern073Result.fromJson(Map<String, dynamic> json) =>
      Pattern073Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern073Result(message: $message)';
}
