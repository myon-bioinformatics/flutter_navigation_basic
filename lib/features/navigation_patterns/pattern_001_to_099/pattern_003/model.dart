// Pattern 003: BasicReplace
// 現在画面を新しい画面に置き換える Replace 遷移。

class Pattern003Result {
  const Pattern003Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern003Result.fromJson(Map<String, dynamic> json) =>
      Pattern003Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern003Result(message: $message)';
}
