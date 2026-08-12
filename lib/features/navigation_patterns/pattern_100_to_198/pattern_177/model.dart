// Pattern 177: SearchDelegate
// SearchDelegate による検索画面。

class Pattern177Result {
  const Pattern177Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern177Result.fromJson(Map<String, dynamic> json) =>
      Pattern177Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern177Result(message: $message)';
}
