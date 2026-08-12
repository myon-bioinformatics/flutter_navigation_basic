// Pattern 175: RemoveItem
// リストからのアイテム削除アニメーション。

class Pattern175Result {
  const Pattern175Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern175Result.fromJson(Map<String, dynamic> json) =>
      Pattern175Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern175Result(message: $message)';
}
