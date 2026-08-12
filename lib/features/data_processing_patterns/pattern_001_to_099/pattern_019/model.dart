// Pattern 019: TextIndex
// 全文検索インデックスの構築。

class Pattern019Result {
  const Pattern019Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern019Result.fromJson(Map<String, dynamic> json) =>
      Pattern019Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern019Result(message: $message)';
}
