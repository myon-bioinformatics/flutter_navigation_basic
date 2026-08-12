// Pattern 125: FutureAny
// Future.any による最速レスポンス取得。

class Pattern125Result {
  const Pattern125Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern125Result.fromJson(Map<String, dynamic> json) =>
      Pattern125Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern125Result(message: $message)';
}
