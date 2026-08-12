// Pattern 191: ImageEmbed
// ネットワーク画像の埋め込み表示。

class Pattern191Result {
  const Pattern191Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern191Result.fromJson(Map<String, dynamic> json) =>
      Pattern191Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern191Result(message: $message)';
}
