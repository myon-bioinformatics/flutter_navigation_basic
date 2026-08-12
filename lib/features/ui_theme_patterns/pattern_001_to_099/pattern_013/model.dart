// Pattern 013: Switch
// Switch ウィジェットのスタイル。

class Pattern013Result {
  const Pattern013Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern013Result.fromJson(Map<String, dynamic> json) =>
      Pattern013Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern013Result(message: $message)';
}
