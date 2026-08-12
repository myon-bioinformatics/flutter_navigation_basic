// Pattern 152: EtagCache
// ETag を使った条件付きリクエスト。

class Pattern152Result {
  const Pattern152Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern152Result.fromJson(Map<String, dynamic> json) =>
      Pattern152Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern152Result(message: $message)';
}
