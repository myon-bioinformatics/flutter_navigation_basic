// Pattern 021: NamedRouteBasic
// 基本的な Named Route 定義と遷移。

class Pattern021Result {
  const Pattern021Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern021Result.fromJson(Map<String, dynamic> json) =>
      Pattern021Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern021Result(message: $message)';
}
