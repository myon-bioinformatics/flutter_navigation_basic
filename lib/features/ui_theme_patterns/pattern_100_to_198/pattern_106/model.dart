// Pattern 106: EyeComfort
// 目に優しい低輝度テーマ。

class Pattern106Result {
  const Pattern106Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern106Result.fromJson(Map<String, dynamic> json) =>
      Pattern106Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern106Result(message: $message)';
}
