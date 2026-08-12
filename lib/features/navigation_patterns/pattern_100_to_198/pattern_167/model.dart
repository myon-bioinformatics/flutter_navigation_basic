// Pattern 167: Tooltip
// Tooltip でヒントを表示。

class Pattern167Result {
  const Pattern167Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern167Result.fromJson(Map<String, dynamic> json) =>
      Pattern167Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern167Result(message: $message)';
}
