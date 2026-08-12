// Pattern 177: MoveToTop
// アイテムをリスト先頭に移動。

class Pattern177Result {
  const Pattern177Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern177Result.fromJson(Map<String, dynamic> json) =>
      Pattern177Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern177Result(message: $message)';
}
