// Pattern 056: TlsVerify
// TLS 証明書検証の実装。

class Pattern056Result {
  const Pattern056Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern056Result.fromJson(Map<String, dynamic> json) =>
      Pattern056Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern056Result(message: $message)';
}
