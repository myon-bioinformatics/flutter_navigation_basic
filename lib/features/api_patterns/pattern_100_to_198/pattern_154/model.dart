// Pattern 154: CacheControl
// Cache-Control ヘッダーのパースと適用。

class Pattern154Result {
  const Pattern154Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern154Result.fromJson(Map<String, dynamic> json) =>
      Pattern154Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern154Result(message: $message)';
}
