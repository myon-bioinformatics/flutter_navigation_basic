// Pattern 188: BoldText
// 太字テキスト設定の検出と対応。

class Pattern188Result {
  const Pattern188Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern188Result.fromJson(Map<String, dynamic> json) =>
      Pattern188Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern188Result(message: $message)';
}
