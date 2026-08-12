// Pattern 169: NoCacheHeader
// no-cache ヘッダーによるキャッシュ無効化。

class Pattern169Result {
  const Pattern169Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern169Result.fromJson(Map<String, dynamic> json) =>
      Pattern169Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern169Result(message: $message)';
}
