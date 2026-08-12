// Pattern 036: JwtDecode
// JWT ペイロードのデコードと検証 (標準ライブラリ)。

class Pattern036Result {
  const Pattern036Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern036Result.fromJson(Map<String, dynamic> json) =>
      Pattern036Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern036Result(message: $message)';
}
