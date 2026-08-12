// Pattern 145: MaterialMotion
// Material Motion アニメーション遷移。

class Pattern145Result {
  const Pattern145Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern145Result.fromJson(Map<String, dynamic> json) =>
      Pattern145Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern145Result(message: $message)';
}
