// Pattern 008: SearchHistory
// 検索履歴の保存と表示。

class Pattern008Result {
  const Pattern008Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern008Result.fromJson(Map<String, dynamic> json) =>
      Pattern008Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern008Result(message: $message)';
}
