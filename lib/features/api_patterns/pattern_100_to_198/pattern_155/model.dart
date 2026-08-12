// Pattern 155: MemoryCache
// メモリ内 LRU キャッシュ実装。

class Pattern155Result {
  const Pattern155Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern155Result.fromJson(Map<String, dynamic> json) =>
      Pattern155Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern155Result(message: $message)';
}
