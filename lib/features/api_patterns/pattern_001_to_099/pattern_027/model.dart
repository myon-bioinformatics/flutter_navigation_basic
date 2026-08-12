// Pattern 027: Redirect
// リダイレクト追跡付き HTTP リクエスト。

class Pattern027Result {
  const Pattern027Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern027Result.fromJson(Map<String, dynamic> json) =>
      Pattern027Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern027Result(message: $message)';
}
