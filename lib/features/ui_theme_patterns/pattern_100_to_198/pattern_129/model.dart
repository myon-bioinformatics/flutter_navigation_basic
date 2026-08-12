// Pattern 129: LayoutBuilder
// LayoutBuilder で親サイズに応じた UI。

class Pattern129Result {
  const Pattern129Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern129Result.fromJson(Map<String, dynamic> json) =>
      Pattern129Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern129Result(message: $message)';
}
