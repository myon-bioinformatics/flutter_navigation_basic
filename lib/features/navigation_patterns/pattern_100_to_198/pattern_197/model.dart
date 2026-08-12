// Pattern 197: MultiWindowNav
// 複数ウィンドウ (デスクトップ) ナビゲーション。

class Pattern197Result {
  const Pattern197Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern197Result.fromJson(Map<String, dynamic> json) =>
      Pattern197Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern197Result(message: $message)';
}
