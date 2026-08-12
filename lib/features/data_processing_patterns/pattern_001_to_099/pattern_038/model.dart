// Pattern 038: Prefetch
// スクロール位置検出による先読み。

class Pattern038Result {
  const Pattern038Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern038Result.fromJson(Map<String, dynamic> json) =>
      Pattern038Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern038Result(message: $message)';
}
