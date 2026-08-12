// Pattern 151: CurveAnimation
// Curves を使ったイージング制御。

class Pattern151Result {
  const Pattern151Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern151Result.fromJson(Map<String, dynamic> json) =>
      Pattern151Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern151Result(message: $message)';
}
