// Pattern 134: WebLayout
// Web 向けセンタリング+最大幅レイアウト。

class Pattern134Result {
  const Pattern134Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern134Result.fromJson(Map<String, dynamic> json) =>
      Pattern134Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern134Result(message: $message)';
}
