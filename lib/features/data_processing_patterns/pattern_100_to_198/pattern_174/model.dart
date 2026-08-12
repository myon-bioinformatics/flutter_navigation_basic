// Pattern 174: InsertItem
// リストへのアイテム挿入アニメーション。

class Pattern174Result {
  const Pattern174Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern174Result.fromJson(Map<String, dynamic> json) =>
      Pattern174Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern174Result(message: $message)';
}
