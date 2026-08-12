// Pattern 025: NavigationBar
// M3 NavigationBar の実装。

class Pattern025Result {
  const Pattern025Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern025Result.fromJson(Map<String, dynamic> json) =>
      Pattern025Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern025Result(message: $message)';
}
