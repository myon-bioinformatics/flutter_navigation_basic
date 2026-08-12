// Pattern 187: InvertColor
// 色反転モード対応。

class Pattern187Result {
  const Pattern187Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern187Result.fromJson(Map<String, dynamic> json) =>
      Pattern187Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern187Result(message: $message)';
}
