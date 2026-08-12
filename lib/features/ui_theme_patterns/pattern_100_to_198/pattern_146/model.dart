// Pattern 146: CustomScroll
// CustomScrollView と Sliver の組み合わせ。

class Pattern146Result {
  const Pattern146Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern146Result.fromJson(Map<String, dynamic> json) =>
      Pattern146Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern146Result(message: $message)';
}
