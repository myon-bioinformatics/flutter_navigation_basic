// Pattern 103: ColorBlind
// 色覚バリアフリー対応テーマ。

class Pattern103Result {
  const Pattern103Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern103Result.fromJson(Map<String, dynamic> json) =>
      Pattern103Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern103Result(message: $message)';
}
