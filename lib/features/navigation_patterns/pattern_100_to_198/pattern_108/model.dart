// Pattern 108: BackInterceptor
// バック操作を横取りして処理を挟む。

class Pattern108Result {
  const Pattern108Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern108Result.fromJson(Map<String, dynamic> json) =>
      Pattern108Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern108Result(message: $message)';
}
