// Pattern 194: SocialLogin
// SNS ログイン後のナビゲーションフロー。

class Pattern194Result {
  const Pattern194Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern194Result.fromJson(Map<String, dynamic> json) =>
      Pattern194Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern194Result(message: $message)';
}
