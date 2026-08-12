// Pattern 134: NavigatorKey
// 特定 Navigator を操作するキー管理。

class Pattern134Result {
  const Pattern134Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern134Result.fromJson(Map<String, dynamic> json) =>
      Pattern134Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern134Result(message: $message)';
}
