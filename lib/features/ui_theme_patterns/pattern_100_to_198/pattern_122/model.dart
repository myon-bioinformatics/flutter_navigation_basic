// Pattern 122: BreakPoint
// ブレークポイント定義とウィジェット切り替え。

class Pattern122Result {
  const Pattern122Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern122Result.fromJson(Map<String, dynamic> json) =>
      Pattern122Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern122Result(message: $message)';
}
