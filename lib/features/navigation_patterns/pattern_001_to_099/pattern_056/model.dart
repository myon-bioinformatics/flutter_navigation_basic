// Pattern 056: DeepLinkHistory
// ブラウザ履歴との連携 (Web)。

class Pattern056Result {
  const Pattern056Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern056Result.fromJson(Map<String, dynamic> json) =>
      Pattern056Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern056Result(message: $message)';
}
