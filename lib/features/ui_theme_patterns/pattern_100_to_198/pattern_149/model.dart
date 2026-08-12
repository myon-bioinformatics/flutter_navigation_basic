// Pattern 149: AdaptiveFont
// 画面サイズに応じたフォントサイズ調整。

class Pattern149Result {
  const Pattern149Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern149Result.fromJson(Map<String, dynamic> json) =>
      Pattern149Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern149Result(message: $message)';
}
