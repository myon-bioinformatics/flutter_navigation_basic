// Pattern 121: ResponsiveLayout
// 画面幅に応じたレイアウト切り替え。

class Pattern121Result {
  const Pattern121Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern121Result.fromJson(Map<String, dynamic> json) =>
      Pattern121Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern121Result(message: $message)';
}
