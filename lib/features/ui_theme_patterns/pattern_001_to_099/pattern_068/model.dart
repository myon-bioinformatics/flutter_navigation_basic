// Pattern 068: MultiTheme
// 複数テーマ選択 UI の実装。

class Pattern068Result {
  const Pattern068Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern068Result.fromJson(Map<String, dynamic> json) =>
      Pattern068Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern068Result(message: $message)';
}
