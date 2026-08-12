// Pattern 176: FormDialog
// フォーム入力ダイアログ。

class Pattern176Result {
  const Pattern176Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern176Result.fromJson(Map<String, dynamic> json) =>
      Pattern176Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern176Result(message: $message)';
}
