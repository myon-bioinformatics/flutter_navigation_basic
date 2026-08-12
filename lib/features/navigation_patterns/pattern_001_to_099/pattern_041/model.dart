// Pattern 041: DeepLinkBasic
// 基本的なディープリンク処理。

class Pattern041Result {
  const Pattern041Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern041Result.fromJson(Map<String, dynamic> json) =>
      Pattern041Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern041Result(message: $message)';
}
