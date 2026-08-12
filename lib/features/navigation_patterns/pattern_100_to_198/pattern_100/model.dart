// Pattern 100: ProfileCompletion
// プロフィール未完了時のリダイレクト。

class Pattern100Result {
  const Pattern100Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern100Result.fromJson(Map<String, dynamic> json) =>
      Pattern100Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern100Result(message: $message)';
}
