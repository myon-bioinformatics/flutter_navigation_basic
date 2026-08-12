// Pattern 063: TtlCache
// TTL 付きキャッシュ実装。

class Pattern063Result {
  const Pattern063Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern063Result.fromJson(Map<String, dynamic> json) =>
      Pattern063Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern063Result(message: $message)';
}
