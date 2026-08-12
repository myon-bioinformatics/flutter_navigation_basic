// Pattern 043: CupertinoContext
// CupertinoContextMenu の実装。

class Pattern043Result {
  const Pattern043Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern043Result.fromJson(Map<String, dynamic> json) =>
      Pattern043Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern043Result(message: $message)';
}
