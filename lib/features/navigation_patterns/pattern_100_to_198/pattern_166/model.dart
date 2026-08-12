// Pattern 166: SnackBar
// SnackBar によるフィードバック表示。

class Pattern166Result {
  const Pattern166Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern166Result.fromJson(Map<String, dynamic> json) =>
      Pattern166Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern166Result(message: $message)';
}
