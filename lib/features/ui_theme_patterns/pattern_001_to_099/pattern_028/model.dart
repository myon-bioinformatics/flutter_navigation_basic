// Pattern 028: SearchBar
// M3 SearchBar の実装。

class Pattern028Result {
  const Pattern028Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern028Result.fromJson(Map<String, dynamic> json) =>
      Pattern028Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern028Result(message: $message)';
}
