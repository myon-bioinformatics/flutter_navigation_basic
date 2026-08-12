// Pattern 119: ThemePreview
// テーマ変更のリアルタイムプレビュー。

class Pattern119Result {
  const Pattern119Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern119Result.fromJson(Map<String, dynamic> json) =>
      Pattern119Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern119Result(message: $message)';
}
