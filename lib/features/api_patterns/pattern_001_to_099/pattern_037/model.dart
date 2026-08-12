// Pattern 037: OAuth2Code
// OAuth2 認可コードフロー (擬似実装)。

class Pattern037Result {
  const Pattern037Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern037Result.fromJson(Map<String, dynamic> json) =>
      Pattern037Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern037Result(message: $message)';
}
