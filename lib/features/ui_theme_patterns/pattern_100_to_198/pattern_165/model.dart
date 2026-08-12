// Pattern 165: StatusBarTransparent
// 透明ステータスバーの実装。

class Pattern165Result {
  const Pattern165Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern165Result.fromJson(Map<String, dynamic> json) =>
      Pattern165Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern165Result(message: $message)';
}
