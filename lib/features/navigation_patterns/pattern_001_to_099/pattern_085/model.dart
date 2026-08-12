// Pattern 085: ConditionalHome
// ログイン状態に応じたホーム画面切り替え。

class Pattern085Result {
  const Pattern085Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern085Result.fromJson(Map<String, dynamic> json) =>
      Pattern085Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern085Result(message: $message)';
}
