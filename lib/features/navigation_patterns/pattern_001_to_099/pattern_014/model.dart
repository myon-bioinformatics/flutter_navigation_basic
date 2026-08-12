// Pattern 014: BottomNavBar
// BottomNavigationBar による複数タブ遷移。

class Pattern014Result {
  const Pattern014Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern014Result.fromJson(Map<String, dynamic> json) =>
      Pattern014Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern014Result(message: $message)';
}
