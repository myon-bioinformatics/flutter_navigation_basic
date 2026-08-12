// Pattern 130: MediaQuery
// MediaQuery で画面情報を取得してレイアウト。

class Pattern130Result {
  const Pattern130Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern130Result.fromJson(Map<String, dynamic> json) =>
      Pattern130Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern130Result(message: $message)';
}
