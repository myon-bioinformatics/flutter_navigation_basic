// Pattern 112: HistoryView
// 遷移履歴を一覧表示。

class Pattern112Result {
  const Pattern112Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern112Result.fromJson(Map<String, dynamic> json) =>
      Pattern112Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern112Result(message: $message)';
}
