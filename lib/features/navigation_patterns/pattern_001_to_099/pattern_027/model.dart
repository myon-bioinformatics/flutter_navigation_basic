// Pattern 027: NamedRouteNested
// 名前付きルートのネスト構造実装。

class Pattern027Result {
  const Pattern027Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern027Result.fromJson(Map<String, dynamic> json) =>
      Pattern027Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern027Result(message: $message)';
}
