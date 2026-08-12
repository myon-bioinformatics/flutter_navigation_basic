// Pattern 059: DeepLinkAnalytics
// ディープリンク遷移をアナリティクス送信。

class Pattern059Result {
  const Pattern059Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern059Result.fromJson(Map<String, dynamic> json) =>
      Pattern059Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern059Result(message: $message)';
}
