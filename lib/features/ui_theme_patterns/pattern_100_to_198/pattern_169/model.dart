// Pattern 169: MouseRegion
// マウスカーソル領域検出 (デスクトップ)。

class Pattern169Result {
  const Pattern169Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern169Result.fromJson(Map<String, dynamic> json) =>
      Pattern169Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern169Result(message: $message)';
}
