// Pattern 147: Responsive2Col
// レスポンシブ 2 カラムレイアウト。

class Pattern147Result {
  const Pattern147Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern147Result.fromJson(Map<String, dynamic> json) =>
      Pattern147Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern147Result(message: $message)';
}
