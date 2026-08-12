// Pattern 115: Constraint
// 制約定義によるデータ整合性チェック。

class Pattern115Result {
  const Pattern115Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern115Result.fromJson(Map<String, dynamic> json) =>
      Pattern115Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern115Result(message: $message)';
}
