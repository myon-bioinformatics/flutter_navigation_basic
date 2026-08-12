// Pattern 016: PageView
// PageView によるページスワイプ遷移。

class Pattern016Result {
  const Pattern016Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern016Result.fromJson(Map<String, dynamic> json) =>
      Pattern016Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern016Result(message: $message)';
}
