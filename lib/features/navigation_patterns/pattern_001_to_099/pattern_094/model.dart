// Pattern 094: TwoFactor
// 2段階認証フロー遷移。

class Pattern094Result {
  const Pattern094Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern094Result.fromJson(Map<String, dynamic> json) =>
      Pattern094Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern094Result(message: $message)';
}
