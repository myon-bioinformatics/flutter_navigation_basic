// Pattern 172: TimePicker
// 時刻選択ダイアログ。

class Pattern172Result {
  const Pattern172Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern172Result.fromJson(Map<String, dynamic> json) =>
      Pattern172Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern172Result(message: $message)';
}
