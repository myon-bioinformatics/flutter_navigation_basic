// Pattern 171: ScrollPhysics
// プラットフォーム別スクロール物理設定。

class Pattern171Result {
  const Pattern171Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern171Result.fromJson(Map<String, dynamic> json) =>
      Pattern171Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern171Result(message: $message)';
}
