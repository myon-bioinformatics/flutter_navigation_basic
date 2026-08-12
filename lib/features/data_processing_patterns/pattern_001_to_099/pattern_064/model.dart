// Pattern 064: WeakRefCache
// 弱参照を使ったキャッシュ実装 (擬似)。

class Pattern064Result {
  const Pattern064Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern064Result.fromJson(Map<String, dynamic> json) =>
      Pattern064Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern064Result(message: $message)';
}
