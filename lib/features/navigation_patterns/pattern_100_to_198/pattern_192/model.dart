// Pattern 192: ShareContent
// コンテンツシェア後の画面遷移フロー。

class Pattern192Result {
  const Pattern192Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern192Result.fromJson(Map<String, dynamic> json) =>
      Pattern192Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern192Result(message: $message)';
}
