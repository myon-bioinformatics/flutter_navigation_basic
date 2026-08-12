// Pattern 022: HttpOptions
// OPTIONS リクエストで許可メソッド確認。

class Pattern022Result {
  const Pattern022Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern022Result.fromJson(Map<String, dynamic> json) =>
      Pattern022Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern022Result(message: $message)';
}
