// Pattern 067: TabBarScrollable
// スクロール可能 TabBar の実装。

class Pattern067Result {
  const Pattern067Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern067Result.fromJson(Map<String, dynamic> json) =>
      Pattern067Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern067Result(message: $message)';
}
