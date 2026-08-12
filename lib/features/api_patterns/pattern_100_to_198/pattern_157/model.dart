// Pattern 157: CacheExpiry
// TTL による期限切れキャッシュの無効化。

class Pattern157Result {
  const Pattern157Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern157Result.fromJson(Map<String, dynamic> json) =>
      Pattern157Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern157Result(message: $message)';
}
