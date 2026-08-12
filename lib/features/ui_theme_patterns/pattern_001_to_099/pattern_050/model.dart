// Pattern 050: CupertinoScaffold
// CupertinoPageScaffold の実装。

class Pattern050Result {
  const Pattern050Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern050Result.fromJson(Map<String, dynamic> json) =>
      Pattern050Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern050Result(message: $message)';
}
