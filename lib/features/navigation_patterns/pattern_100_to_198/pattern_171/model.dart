// Pattern 171: DatePicker
// 日付選択ダイアログ。

class Pattern171Result {
  const Pattern171Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern171Result.fromJson(Map<String, dynamic> json) =>
      Pattern171Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern171Result(message: $message)';
}
