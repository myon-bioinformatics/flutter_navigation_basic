// Pattern 048: Pkce
// PKCE フローによる OAuth2 実装。

class Pattern048Result {
  const Pattern048Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern048Result.fromJson(Map<String, dynamic> json) =>
      Pattern048Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern048Result(message: $message)';
}
