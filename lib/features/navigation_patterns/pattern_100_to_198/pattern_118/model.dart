// Pattern 118: NavigationStack
// 画面スタックをリスト操作でコントロール。

class Pattern118Result {
  const Pattern118Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern118Result.fromJson(Map<String, dynamic> json) =>
      Pattern118Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern118Result(message: $message)';
}
