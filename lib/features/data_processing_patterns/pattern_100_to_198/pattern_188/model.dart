// Pattern 188: EventDriven
// イベント駆動アーキテクチャの実装。

class Pattern188Result {
  const Pattern188Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern188Result.fromJson(Map<String, dynamic> json) =>
      Pattern188Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern188Result(message: $message)';
}
