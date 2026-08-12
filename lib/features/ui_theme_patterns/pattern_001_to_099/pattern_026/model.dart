// Pattern 026: NavigationDrawer
// M3 NavigationDrawer の実装。

class Pattern026Result {
  const Pattern026Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern026Result.fromJson(Map<String, dynamic> json) =>
      Pattern026Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern026Result(message: $message)';
}
