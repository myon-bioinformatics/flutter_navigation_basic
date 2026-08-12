// Pattern 074: DrawerHeader
// ユーザー情報を表示する DrawerHeader。

class Pattern074Result {
  const Pattern074Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern074Result.fromJson(Map<String, dynamic> json) =>
      Pattern074Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern074Result(message: $message)';
}
