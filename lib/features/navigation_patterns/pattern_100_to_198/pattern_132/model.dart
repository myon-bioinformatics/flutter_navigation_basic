// Pattern 132: ChildNavigator
// 子画面専用の Navigator 実装。

class Pattern132Result {
  const Pattern132Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern132Result.fromJson(Map<String, dynamic> json) =>
      Pattern132Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern132Result(message: $message)';
}
