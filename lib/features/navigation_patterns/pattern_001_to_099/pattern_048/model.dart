// Pattern 048: DeepLinkFallback
// リンク先不正時のフォールバック処理。

class Pattern048Result {
  const Pattern048Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern048Result.fromJson(Map<String, dynamic> json) =>
      Pattern048Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern048Result(message: $message)';
}
