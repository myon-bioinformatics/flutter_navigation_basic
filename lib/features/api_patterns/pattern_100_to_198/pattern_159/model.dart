// Pattern 159: StaleWhileRevalidate
// Stale-While-Revalidate パターン。

class Pattern159Result {
  const Pattern159Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern159Result.fromJson(Map<String, dynamic> json) =>
      Pattern159Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern159Result(message: $message)';
}
