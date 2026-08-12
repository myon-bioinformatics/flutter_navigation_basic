// Pattern 081: AuthGuard
// 未認証時にログイン画面へリダイレクト。

class Pattern081Result {
  const Pattern081Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern081Result.fromJson(Map<String, dynamic> json) =>
      Pattern081Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern081Result(message: $message)';
}
