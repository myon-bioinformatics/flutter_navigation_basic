// Pattern 033: InfiniteScroll
// 無限スクロール実装。

class Pattern033Result {
  const Pattern033Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern033Result.fromJson(Map<String, dynamic> json) =>
      Pattern033Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern033Result(message: $message)';
}
