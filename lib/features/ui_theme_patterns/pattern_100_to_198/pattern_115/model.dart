// Pattern 115: NightShift
// Night Shift (暖色) モード実装。

class Pattern115Result {
  const Pattern115Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern115Result.fromJson(Map<String, dynamic> json) =>
      Pattern115Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern115Result(message: $message)';
}
