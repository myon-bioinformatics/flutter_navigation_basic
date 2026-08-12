// Pattern 045: SessionCookie
// Cookie セッション管理 (擬似実装)。

class Pattern045Result {
  const Pattern045Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern045Result.fromJson(Map<String, dynamic> json) =>
      Pattern045Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern045Result(message: $message)';
}
