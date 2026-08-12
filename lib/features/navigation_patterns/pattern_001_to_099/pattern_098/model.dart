// Pattern 098: LanguageRedirect
// 言語設定に応じて画面をリダイレクト。

class Pattern098Result {
  const Pattern098Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern098Result.fromJson(Map<String, dynamic> json) =>
      Pattern098Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern098Result(message: $message)';
}
