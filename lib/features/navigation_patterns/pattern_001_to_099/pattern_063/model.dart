// Pattern 063: BottomNavStatePreserve
// タブ切り替え時に状態を保持。

class Pattern063Result {
  const Pattern063Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern063Result.fromJson(Map<String, dynamic> json) =>
      Pattern063Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern063Result(message: $message)';
}
