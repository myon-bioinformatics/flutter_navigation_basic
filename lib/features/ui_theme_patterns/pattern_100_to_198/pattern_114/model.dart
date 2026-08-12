// Pattern 114: ColorHarmony
// 補色・類似色ハーモニーカラー生成。

class Pattern114Result {
  const Pattern114Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern114Result.fromJson(Map<String, dynamic> json) =>
      Pattern114Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern114Result(message: $message)';
}
