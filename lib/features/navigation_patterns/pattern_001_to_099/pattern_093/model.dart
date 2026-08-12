// Pattern 093: KYC
// 本人確認フロー付き条件遷移。

class Pattern093Result {
  const Pattern093Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern093Result.fromJson(Map<String, dynamic> json) =>
      Pattern093Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern093Result(message: $message)';
}
