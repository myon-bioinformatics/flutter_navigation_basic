// Pattern 129: ErrorBoundary
// ウィジェットレベルのエラーバウンダリ。

class Pattern129Result {
  const Pattern129Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern129Result.fromJson(Map<String, dynamic> json) =>
      Pattern129Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern129Result(message: $message)';
}
