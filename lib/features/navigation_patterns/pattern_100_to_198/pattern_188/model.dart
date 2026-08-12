// Pattern 188: DeeplinkToNested
// ディープリンクでネスト Navigator の深い画面へ。

class Pattern188Result {
  const Pattern188Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern188Result.fromJson(Map<String, dynamic> json) =>
      Pattern188Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern188Result(message: $message)';
}
