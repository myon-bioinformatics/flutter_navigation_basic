// Pattern 004: PushWithResult
// 遷移先から結果を受け取る Push & Return値。

class Pattern004Result {
  const Pattern004Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern004Result.fromJson(Map<String, dynamic> json) =>
      Pattern004Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern004Result(message: $message)';
}
