// Pattern 112: TonalPalette
// Tonal Palette によるカラー生成。

class Pattern112Result {
  const Pattern112Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern112Result.fromJson(Map<String, dynamic> json) =>
      Pattern112Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern112Result(message: $message)';
}
