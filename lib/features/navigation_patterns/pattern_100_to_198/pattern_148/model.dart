// Pattern 148: CustomSlide
// カスタムスライド方向の遷移アニメーション。

class Pattern148Result {
  const Pattern148Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern148Result.fromJson(Map<String, dynamic> json) =>
      Pattern148Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern148Result(message: $message)';
}
