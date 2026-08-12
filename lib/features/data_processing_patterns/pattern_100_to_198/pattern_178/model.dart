// Pattern 178: MoveToBottom
// アイテムをリスト末尾に移動。

class Pattern178Result {
  const Pattern178Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern178Result.fromJson(Map<String, dynamic> json) =>
      Pattern178Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern178Result(message: $message)';
}
