// Pattern 192: SwipeAction
// スワイプアクション (右/左スワイプ) 実装。

class Pattern192Result {
  const Pattern192Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern192Result.fromJson(Map<String, dynamic> json) =>
      Pattern192Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern192Result(message: $message)';
}
