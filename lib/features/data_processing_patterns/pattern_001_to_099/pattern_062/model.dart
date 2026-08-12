// Pattern 062: LruCache
// LRU (最近最未使用) キャッシュ実装。

class Pattern062Result {
  const Pattern062Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern062Result.fromJson(Map<String, dynamic> json) =>
      Pattern062Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern062Result(message: $message)';
}
