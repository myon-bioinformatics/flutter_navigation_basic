// Pattern 020: Stepper
// Stepper ウィジェットのカスタマイズ。

class Pattern020Result {
  const Pattern020Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern020Result.fromJson(Map<String, dynamic> json) =>
      Pattern020Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern020Result(message: $message)';
}
