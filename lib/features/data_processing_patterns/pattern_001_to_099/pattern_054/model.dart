// Pattern 054: ChecklistView
// チェックリスト形式のリスト。

class Pattern054Result {
  const Pattern054Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern054Result.fromJson(Map<String, dynamic> json) =>
      Pattern054Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern054Result(message: $message)';
}
