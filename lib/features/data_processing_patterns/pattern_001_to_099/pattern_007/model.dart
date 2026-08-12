// Pattern 007: SearchHighlight
// 検索キーワードのハイライト表示。

class Pattern007Result {
  const Pattern007Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern007Result.fromJson(Map<String, dynamic> json) =>
      Pattern007Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern007Result(message: $message)';
}
