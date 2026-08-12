// Pattern 106: BackGesture
// スワイプバックジェスチャー制御。

class Pattern106Result {
  const Pattern106Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern106Result.fromJson(Map<String, dynamic> json) =>
      Pattern106Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern106Result(message: $message)';
}
