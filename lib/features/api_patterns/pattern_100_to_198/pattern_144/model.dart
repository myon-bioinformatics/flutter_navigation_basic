// Pattern 144: OfflineMode
// オフライン時のキャッシュフォールバック。

class Pattern144Result {
  const Pattern144Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern144Result.fromJson(Map<String, dynamic> json) =>
      Pattern144Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern144Result(message: $message)';
}
